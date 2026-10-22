// Bridge tool that delegates a self-contained task to the pinned Antigravity
// CLI (`agy`, from aiPackages.antigravity-cli) as a second-opinion agent.
// The child agent never sees this Pi session's transcript: the caller must
// inline every file path, decision, and constraint into `prompt`.
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

const AGY_BIN = "agy";
const DEFAULT_TIMEOUT_SECONDS = 600;
const MAX_TIMEOUT_SECONDS = 3600;
// Keep model-facing results bounded; point the model at files for full output.
const MAX_RESULT_CHARS = 40_000;
const MAX_STDERR_CHARS = 2_000;

const AgyBridgeParams = Type.Object({
  prompt: Type.String({
    description:
      "Complete, self-contained task for the agy agent. Include all context it needs: relevant file paths, code excerpts, constraints, and the expected deliverable. It cannot see this conversation.",
  }),
  mode: Type.Optional(
    Type.Union([Type.Literal("plan"), Type.Literal("accept-edits")], {
      description:
        "agy execution mode. 'plan' (default) reviews and answers without writing; use it for second opinions and reviews. 'accept-edits' lets agy edit files under cwd directly.",
    }),
  ),
  model: Type.Optional(
    Type.String({
      description:
        "Model alias or id for the agy session (e.g. 'flash', 'pro', 'gemini'). Omit to use agy's configured default.",
    }),
  ),
  effort: Type.Optional(
    Type.Union(
      [Type.Literal("low"), Type.Literal("medium"), Type.Literal("high"), Type.Literal("max")],
      {
        description: "Reasoning effort for the agy session. Omit for agy's default.",
      },
    ),
  ),
  cwd: Type.Optional(
    Type.String({
      description:
        "Absolute working directory for the agy session. Defaults to this Pi session's working directory.",
    }),
  ),
  timeoutSeconds: Type.Optional(
    Type.Number({
      minimum: 1,
      maximum: MAX_TIMEOUT_SECONDS,
      description: `Overall limit for the agy run (default ${DEFAULT_TIMEOUT_SECONDS}s).`,
    }),
  ),
});

function truncate(text: string, limit: number): { text: string; truncated: boolean } {
  if (text.length <= limit) {
    return { text, truncated: false };
  }
  return { text: `${text.slice(0, limit)}\n[...truncated ${text.length - limit} characters]`, truncated: true };
}

export default function agyBridge(pi: ExtensionAPI) {
  pi.registerTool({
    name: "agy",
    label: "agy bridge",
    description:
      "Delegate a self-contained task to the Antigravity (Gemini) CLI for an independent second opinion or isolated sub-task. The agent cannot see this conversation: inline all needed context in the prompt. Use for cross-model review, alternative reasoning, or self-contained chores; keep ordinary work in this session.",
    promptSnippet:
      "Use the agy tool for a second opinion from a different model family or for a self-contained isolated sub-task.",
    promptGuidelines: [
      "The prompt must be fully self-contained; the agy agent has no access to this conversation or its context.",
      "Default to mode 'plan' (read-only) for reviews and analysis; use 'accept-edits' only when agy should write files.",
      "Prefer one focused task per call over bundling unrelated questions.",
      "Quote the relevant code or file paths in the prompt instead of referring to them vaguely.",
    ],
    parameters: AgyBridgeParams,

    async execute(_toolCallId, params, signal, _onUpdate, _ctx) {
      const timeoutSeconds = Math.min(
        Math.max(Math.round(params.timeoutSeconds ?? DEFAULT_TIMEOUT_SECONDS), 1),
        MAX_TIMEOUT_SECONDS,
      );
      const mode = params.mode ?? "plan";
      const cwd = params.cwd ?? process.cwd();

      if (signal?.aborted) {
        throw new Error("agy bridge: aborted before the agent started");
      }

      const args = ["--print", params.prompt, "--mode", mode, "--output-format", "text"];
      if (params.model) {
        args.push("--model", params.model);
      }
      if (params.effort) {
        args.push("--effort", params.effort);
      }
      // agy's own deadline matches ours; execFile's timeout is the hard stop.
      args.push("--print-timeout", `${timeoutSeconds}s`);

      const startedAt = Date.now();
      let stdout: string;
      try {
        const result = await execFileAsync(AGY_BIN, args, {
          cwd,
          timeout: timeoutSeconds * 1000,
          maxBuffer: 16 * 1024 * 1024,
          signal,
          windowsHide: true,
        });
        stdout = result.stdout;
      } catch (error) {
        const err = error as NodeJS.ErrnoException & {
          code?: string | number;
          stderr?: string;
          killed?: boolean;
          stdout?: string;
        };
        if (signal?.aborted || err.killed) {
          throw new Error(`agy bridge: agent run exceeded ${timeoutSeconds}s and was terminated`);
        }
        if (err.code === "ENOENT") {
          throw new Error(
            `agy bridge: '${AGY_BIN}' not found on PATH; the antigravity-cli package must be installed`,
          );
        }
        const stderr = truncate((err.stderr ?? "").trim(), MAX_STDERR_CHARS).text;
        const partial = truncate((err.stdout ?? "").trim(), MAX_RESULT_CHARS).text;
        const detail = [stderr, partial].filter(Boolean).join("\n");
        throw new Error(`agy bridge: agent exited with code ${err.code}${detail ? `:\n${detail}` : ""}`);
      }

      const answer = truncate(stdout.trim(), MAX_RESULT_CHARS);
      const durationMs = Date.now() - startedAt;
      return {
        content: [
          {
            type: "text" as const,
            text: answer.text,
          },
        ],
        details: {
          mode,
          model: params.model ?? null,
          effort: params.effort ?? null,
          cwd,
          durationMs,
          exitCode: 0,
          truncated: answer.truncated,
        },
      };
    },
  });
}
