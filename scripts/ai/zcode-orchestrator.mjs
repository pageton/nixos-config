#!/usr/bin/env node

import process from "node:process";
import {
  ApprovalStore,
  ORCHESTRATOR_VERSION,
  Orchestrator,
  createRuntimeConfig,
} from "./zcode-orchestrator-core.mjs";

const GIT_MUTATION_PATTERN =
  /\b(?:[^\s;&|]+\/)?git\b[^;&|]*\b(add|am|bisect|branch|checkout|cherry-pick|clean|clone|commit|config|gc|init|maintenance|merge|mv|notes|pack-refs|prune|pull|push|rebase|reflog|remote|replace|reset|restore|revert|rm|sparse-checkout|stash|submodule|switch|tag|update-index|worktree)\b/iu;
const GITHUB_MUTATION_PATTERN =
  /\bgh\s+(?:(?:pr\s+(?:close|create|edit|merge|ready|reopen|review))|(?:issue\s+(?:close|create|edit|reopen))|(?:release\s+(?:create|delete|edit|upload))|(?:repo\s+(?:archive|create|delete|edit|fork|rename|sync))|(?:workflow\s+run)|(?:api\b[^\n]*(?:--method|-X)\s*(?:DELETE|PATCH|POST|PUT)))\b/iu;
const SECRET_ENVIRONMENT_NAMES = [
  "ANTHROPIC_API_KEY",
  "DEEPSEEK_API_KEY",
  "GITHUB_TOKEN",
  "GH_TOKEN",
  "MIMO_API_KEY",
  "OPENAI_API_KEY",
  "OPENROUTER_API_KEY",
  "ZAI_API_KEY",
];

function hookResult(eventName, fields) {
  return {
    hookSpecificOutput: {
      hookEventName: eventName,
      ...fields,
    },
  };
}

async function readStandardInput() {
  const chunks = [];
  for await (const chunk of process.stdin) chunks.push(chunk);
  return Buffer.concat(chunks).toString("utf8");
}

function writeHookResponse(value) {
  process.stdout.write(`${JSON.stringify(value)}\n`);
}

async function runAgentGate() {
  let input;
  try {
    input = JSON.parse(await readStandardInput());
  } catch {
    writeHookResponse(
      hookResult("PreToolUse", {
        permissionDecision: "deny",
        permissionDecisionReason: "Orchestration capability gate received invalid hook input.",
      }),
    );
    process.exitCode = 2;
    return;
  }

  const toolName = input.tool_name ?? input.toolName ?? "";
  if (toolName !== "Bash") {
    writeHookResponse({});
    return;
  }
  const toolInput = input.tool_input ?? input.toolInput ?? {};
  const command = typeof toolInput.command === "string" ? toolInput.command : "";
  if (GIT_MUTATION_PATTERN.test(command) || GITHUB_MUTATION_PATTERN.test(command)) {
    writeHookResponse(
      hookResult("PreToolUse", {
        permissionDecision: "deny",
        permissionDecisionReason:
          "Sub-agents cannot mutate local or remote Git state. Use the orchestrator's approval-gated Git tools after the run completes.",
      }),
    );
    process.exitCode = 2;
    return;
  }

  const unsetCommand = `unset ${SECRET_ENVIRONMENT_NAMES.join(" ")};`;
  writeHookResponse(
    hookResult("PreToolUse", {
      permissionDecision: "allow",
      permissionDecisionReason: "Orchestration capability gate removed provider credentials from the command environment.",
      updatedInput: {
        ...toolInput,
        command: `${unsetCommand}\n${command}`,
      },
    }),
  );
}

async function runApprovalHook() {
  let input;
  try {
    input = JSON.parse(await readStandardInput());
  } catch {
    writeHookResponse({});
    return;
  }
  const prompt = input.prompt ?? input.user_prompt ?? input.userPrompt ?? "";
  if (typeof prompt !== "string" || !/^APPROVE (RUN|GIT|ROLLBACK) [A-F0-9]{12}$/u.test(prompt.trim())) {
    writeHookResponse({});
    return;
  }
  const config = createRuntimeConfig();
  const approvals = new ApprovalStore(config.stateDir);
  try {
    const recorded = await approvals.recordPrompt(prompt);
    writeHookResponse(
      hookResult("UserPromptSubmit", {
        additionalContext: `Recorded one-time ${recorded.kind} approval token ${recorded.token}. The orchestrator may now consume it exactly once.`,
      }),
    );
  } catch (error) {
    writeHookResponse(
      hookResult("UserPromptSubmit", {
        additionalContext: `Approval was not recorded: ${error instanceof Error ? error.message : String(error)}`,
      }),
    );
  }
}

const TOOLS = [
  {
    name: "orchestrate",
    description:
      "Classify a task, build a dependency-aware ZCode sub-agent plan, and either return the plan or start isolated execution. Returns immediately for execution; inspect progress with orchestration_status.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      required: ["task"],
      properties: {
        task: { type: "string", minLength: 1, maxLength: 40000 },
        workspace: { type: "string", description: "Absolute or process-relative workspace directory." },
        mode: { type: "string", enum: ["execute", "plan"], default: "execute" },
        forcePerformance: { type: "boolean", default: false },
        requireApproval: {
          type: "boolean",
          default: false,
          description: "Require an explicit one-time RUN approval even for low/medium-risk work.",
        },
      },
    },
  },
  {
    name: "orchestration_status",
    description: "Return bounded structured status and results for one orchestration run.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      required: ["runId"],
      properties: {
        runId: { type: "string" },
        waitMs: { type: "integer", minimum: 0, maximum: 50000, default: 0 },
      },
    },
  },
  {
    name: "orchestration_cancel",
    description: "Cancel an active orchestration run and its current child process tree.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      required: ["runId"],
      properties: { runId: { type: "string" } },
    },
  },
  {
    name: "orchestration_approve",
    description:
      "Start a high-risk run after the user has submitted its exact APPROVE RUN phrase and the UserPromptSubmit hook recorded it.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      required: ["runId", "token"],
      properties: {
        runId: { type: "string" },
        token: { type: "string", pattern: "^[A-F0-9]{12}$" },
      },
    },
  },
  {
    name: "git_prepare",
    description:
      "Prepare an exact-path signed commit action for a completed run. Returns a one-time APPROVE GIT phrase; it does not stage, commit, or push.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      required: ["runId", "message"],
      properties: {
        runId: { type: "string" },
        paths: { type: "array", minItems: 1, items: { type: "string" } },
        message: { type: "string", minLength: 1, maxLength: 120 },
        push: { type: "boolean", default: false },
      },
    },
  },
  {
    name: "git_apply",
    description:
      "Consume a user-recorded one-time Git approval, commit only the prepared fingerprints through an isolated index, verify the GPG signature, and optionally perform a non-force push.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      required: ["token"],
      properties: { token: { type: "string", pattern: "^[A-F0-9]{12}$" } },
    },
  },
  {
    name: "rollback_prepare",
    description:
      "Prepare an exact-path rollback for task-owned files without touching pre-existing changes. Returns an APPROVE ROLLBACK phrase and performs no mutation.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      required: ["runId"],
      properties: {
        runId: { type: "string" },
        paths: { type: "array", minItems: 1, items: { type: "string" } },
      },
    },
  },
  {
    name: "rollback_apply",
    description: "Consume a user-recorded rollback approval and restore or remove only the prepared task-owned paths.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      required: ["token"],
      properties: { token: { type: "string", pattern: "^[A-F0-9]{12}$" } },
    },
  },
];

class StdioJsonRpcTransport {
  constructor(onMessage, onEnd = () => {}) {
    this.onMessage = onMessage;
    this.onEnd = onEnd;
    this.buffer = Buffer.alloc(0);
    this.mode = null;
  }

  start() {
    process.stdin.on("data", (chunk) => {
      this.buffer = Buffer.concat([this.buffer, chunk]);
      this.drain();
    });
    process.stdin.on("end", () => {
      if (this.buffer.toString("utf8").trim()) this.parseLine(this.buffer.toString("utf8").trim());
      Promise.resolve(this.onEnd()).catch((error) => {
        process.stderr.write(`zcode-orchestrator: shutdown failed: ${error instanceof Error ? error.stack : String(error)}\n`);
      });
    });
  }

  drain() {
    while (this.buffer.length > 0) {
      if (this.buffer.toString("ascii", 0, Math.min(this.buffer.length, 32)).startsWith("Content-Length:")) {
        const headerEnd = this.buffer.indexOf("\r\n\r\n");
        if (headerEnd < 0) return;
        const header = this.buffer.subarray(0, headerEnd).toString("ascii");
        const match = header.match(/(?:^|\r\n)Content-Length:\s*(\d+)/iu);
        if (!match) throw new Error("invalid Content-Length frame");
        const length = Number.parseInt(match[1], 10);
        const bodyStart = headerEnd + 4;
        if (this.buffer.length < bodyStart + length) return;
        const body = this.buffer.subarray(bodyStart, bodyStart + length).toString("utf8");
        this.buffer = this.buffer.subarray(bodyStart + length);
        this.mode = "content-length";
        this.parseLine(body);
        continue;
      }
      const newline = this.buffer.indexOf("\n");
      if (newline < 0) return;
      const line = this.buffer.subarray(0, newline).toString("utf8").trim();
      this.buffer = this.buffer.subarray(newline + 1);
      if (!line) continue;
      this.mode = "newline";
      this.parseLine(line);
    }
  }

  parseLine(text) {
    let message;
    try {
      message = JSON.parse(text);
    } catch (error) {
      this.send({
        jsonrpc: "2.0",
        id: null,
        error: { code: -32700, message: error instanceof Error ? error.message : "Parse error" },
      });
      return;
    }
    Promise.resolve(this.onMessage(message)).catch((error) => {
      process.stderr.write(`zcode-orchestrator: ${error instanceof Error ? error.stack : String(error)}\n`);
    });
  }

  send(message) {
    const serialized = JSON.stringify(message);
    if (this.mode === "content-length") {
      const length = Buffer.byteLength(serialized);
      process.stdout.write(`Content-Length: ${length}\r\n\r\n${serialized}`);
      return;
    }
    process.stdout.write(`${serialized}\n`);
  }
}

function toolSuccess(value) {
  const serialized = JSON.stringify(value, null, 2);
  return {
    content: [{ type: "text", text: serialized }],
    structuredContent: value,
  };
}

function toolFailure(error) {
  const message = error instanceof Error ? error.message : String(error);
  return {
    content: [{ type: "text", text: message }],
    structuredContent: { status: "failed", error: message },
    isError: true,
  };
}

async function dispatchTool(orchestrator, name, input) {
  switch (name) {
    case "orchestrate":
      return orchestrator.start(input);
    case "orchestration_status":
      return orchestrator.get(input.runId, input.waitMs);
    case "orchestration_cancel":
      return orchestrator.cancel(input.runId);
    case "orchestration_approve":
      return orchestrator.approveRun(input.runId, input.token);
    case "git_prepare":
      return orchestrator.prepareGit(input);
    case "git_apply":
      return orchestrator.applyGit(input.token);
    case "rollback_prepare":
      return orchestrator.prepareRollback(input);
    case "rollback_apply":
      return orchestrator.applyRollback(input.token);
    default:
      throw new Error(`unknown tool: ${name}`);
  }
}

async function runServer() {
  const config = createRuntimeConfig();
  const orchestrator = new Orchestrator(config);
  await orchestrator.initialize();
  let transport;
  transport = new StdioJsonRpcTransport(async (message) => {
    if (!message || message.jsonrpc !== "2.0" || typeof message.method !== "string") return;
    if (message.method === "notifications/initialized" || message.method === "notifications/cancelled") return;
    if (message.id === undefined) return;

    if (message.method === "initialize") {
      transport.send({
        jsonrpc: "2.0",
        id: message.id,
        result: {
          protocolVersion: message.params?.protocolVersion ?? "2025-06-18",
          capabilities: { tools: { listChanged: false } },
          serverInfo: { name: "zcode-orchestrator", version: ORCHESTRATOR_VERSION },
        },
      });
      return;
    }
    if (message.method === "ping") {
      transport.send({ jsonrpc: "2.0", id: message.id, result: {} });
      return;
    }
    if (message.method === "tools/list") {
      transport.send({ jsonrpc: "2.0", id: message.id, result: { tools: TOOLS } });
      return;
    }
    if (message.method === "tools/call") {
      try {
        const result = await dispatchTool(
          orchestrator,
          message.params?.name,
          message.params?.arguments ?? {},
        );
        transport.send({ jsonrpc: "2.0", id: message.id, result: toolSuccess(result) });
      } catch (error) {
        transport.send({ jsonrpc: "2.0", id: message.id, result: toolFailure(error) });
      }
      return;
    }
    transport.send({
      jsonrpc: "2.0",
      id: message.id,
      error: { code: -32601, message: `Method not found: ${message.method}` },
    });
  }, () => orchestrator.shutdown());
  transport.start();
}

const argument = process.argv[2];
if (argument === "--agent-gate") await runAgentGate();
else if (argument === "--approval-hook") await runApprovalHook();
else if (argument === "--version") process.stdout.write(`${ORCHESTRATOR_VERSION}\n`);
else await runServer();
