/**
 * Subagent Extension for pi-coding-agent.
 *
 * Spawns sub-agents in tmux panes when running inside tmux, so the user
 * can watch the subagent work live. Falls back to headless `pi -p` when
 * not in tmux.
 *
 * Uses the tmux wait-for channel protocol for completion signaling and
 * temp files for reliable output capture.
 *
 * Tools:
 *   delegate_task — spawn a single subagent (split, window, or background)
 *
 * Commands:
 *   /delegate — interactive delegation prompt
 */
import { Type } from "@mariozechner/pi-ai";
import {
  defineTool,
  truncateHead,
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  formatSize,
  type ExtensionAPI,
} from "@mariozechner/pi-coding-agent";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import {
  mkdtempSync,
  writeFileSync,
  readFileSync,
  unlinkSync,
  rmSync,
  existsSync,
} from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

const execFileAsync = promisify(execFile);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function isInTmux(): boolean {
  return !!process.env.TMUX;
}

/** Write a temp runner script that executes pi and signals tmux on completion. */
function writeRunnerScript(
  tmpDir: string,
  channel: string,
  cwd: string,
  piArgs: string[],
): string {
  // The prompt is passed via a file to avoid shell escaping nightmares.
  const promptFile = join(tmpDir, "prompt");
  const outFile = join(tmpDir, "output");
  const errFile = join(tmpDir, "stderr");
  const rcFile = join(tmpDir, "rc");

  // Build the pi command — prompt comes from the file.
  const piCmd = ["pi", ...piArgs, '"$(cat "$PROMPT_FILE")"'].join(" ");

  const script = `#!/usr/bin/env bash
set -euo pipefail
PROMPT_FILE="${promptFile}"
cd "${cwd}"
${piCmd} > "${outFile}" 2> "${errFile}" || echo "$?" > "${rcFile}"
[ ! -f "${rcFile}" ] && echo "0" > "${rcFile}"
tmux wait-for -S "${channel}"
`;
  const scriptPath = join(tmpDir, "run.sh");
  writeFileSync(scriptPath, script, { mode: 0o755 });
  return scriptPath;
}

// ---------------------------------------------------------------------------
// Tmux subagent
// ---------------------------------------------------------------------------

async function runTmuxSubagent(
  prompt: string,
  cwd: string,
  options: {
    model?: string;
    files?: string[];
    mode?: "split" | "window";
    timeout?: number;
  },
  signal?: AbortSignal,
): Promise<{ output: string; stderr: string; exitCode: number }> {
  const id = `pi-sub-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
  const channel = `pi-sub-${id}`;
  const tmpDir = mkdtempSync(join(tmpdir(), "pi-sub-"));

  try {
    // Write prompt to file
    writeFileSync(join(tmpDir, "prompt"), prompt);

    // Build pi arguments
    const piArgs = ["-p", "--no-session"];
    if (options.model) piArgs.push("--model", options.model);
    for (const f of options.files ?? []) piArgs.push(`@${f}`);

    // Write runner script
    const scriptPath = writeRunnerScript(tmpDir, channel, cwd, piArgs);

    // Create tmux pane
    const tmuxAction = options.mode === "window" ? "new-window" : "split-window";
    // split-window default is horizontal; use -h for side-by-side (more useful)
    const splitArgs = options.mode === "window" ? [] : ["-h", "-l", "40%"];
    const { stdout: paneId } = await execFileAsync("tmux", [
      tmuxAction,
      ...splitArgs,
      "-P",
      "-F",
      "#{pane_id}",
      "bash",
      scriptPath,
    ]);

    const paneIdTrimmed = paneId.trim();

    // Cleanup on abort
    const onAbort = () => {
      try {
        execFileSync("tmux", ["kill-pane", "-t", paneIdTrimmed]);
      } catch { /* already gone */ }
    };
    signal?.addEventListener("abort", onAbort, { once: true });

    try {
      // Wait for the subagent to signal completion
      await execFileAsync("tmux", ["wait-for", channel], {
        timeout: options.timeout ?? 180_000,
        signal,
      });
    } finally {
      signal?.removeEventListener("abort", onAbort);
    }

    // Read results
    let output = "";
    let stderr = "";
    let exitCode = 0;

    const outFile = join(tmpDir, "output");
    const errFile = join(tmpDir, "stderr");
    const rcFile = join(tmpDir, "rc");

    if (existsSync(outFile)) output = readFileSync(outFile, "utf8").trim();
    if (existsSync(errFile)) stderr = readFileSync(errFile, "utf8").trim();
    if (existsSync(rcFile)) exitCode = parseInt(readFileSync(rcFile, "utf8").trim(), 10) || 1;

    // Kill the pane (it may linger showing "[exited]")
    try {
      await execFileAsync("tmux", ["kill-pane", "-t", paneIdTrimmed]);
    } catch { /* already gone */ }

    return { output, stderr, exitCode };
  } finally {
    // Cleanup temp dir
    try { rmSync(tmpDir, { recursive: true, force: true }); } catch { /* best effort */ }
  }
}

// ---------------------------------------------------------------------------
// Headless subagent (fallback when not in tmux)
// ---------------------------------------------------------------------------

async function runHeadlessSubagent(
  prompt: string,
  cwd: string,
  options: {
    model?: string;
    files?: string[];
    timeout?: number;
  },
  signal?: AbortSignal,
): Promise<{ output: string; stderr: string; exitCode: number }> {
  const args = ["-p", "--no-session"];
  if (options.model) args.push("--model", options.model);
  for (const f of options.files ?? []) args.push(`@${f}`);
  args.push(prompt);

  try {
    const { stdout, stderr } = await execFileAsync("pi", args, {
      cwd,
      maxBuffer: 10 * 1024 * 1024,
      signal,
      timeout: options.timeout ?? 180_000,
      env: {
        ...process.env,
        ...(process.env.PI_CODING_AGENT_DIR
          ? { PI_CODING_AGENT_DIR: process.env.PI_CODING_AGENT_DIR }
          : {}),
      },
    });

    return {
      output: (stdout ?? "").trim(),
      stderr: (stderr ?? "").trim(),
      exitCode: 0,
    };
  } catch (err: any) {
    if (err.killed || err.name === "AbortError") {
      return { output: "(subagent aborted)", stderr: "", exitCode: 1 };
    }
    const output = (err.stdout ?? "").trim();
    const stderr = (err.stderr ?? "").trim();
    return { output, stderr, exitCode: err.code ?? 1 };
  }
}

// ---------------------------------------------------------------------------
// Synchronous execFile for abort handler (can't await in event listener)
// ---------------------------------------------------------------------------

function execFileSync(cmd: string, args: string[]): void {
  try {
    const { execFileSync } = require("node:child_process");
    execFileSync(cmd, args, { timeout: 2000 });
  } catch { /* best effort */ }
}

// ---------------------------------------------------------------------------
// Truncate output to safe limits
// ---------------------------------------------------------------------------

function truncateOutput(text: string): string {
  const result = truncateHead(text, {
    maxLines: DEFAULT_MAX_LINES,
    maxBytes: DEFAULT_MAX_BYTES,
  });

  if (result.truncated) {
    return (
      result.content +
      `\n\n[Output truncated: ${result.outputLines} of ${result.totalLines} lines (${formatSize(result.outputBytes)} of ${formatSize(result.totalBytes)})]`
    );
  }
  return result.content;
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI): void {
  pi.registerTool(
    defineTool({
      name: "delegate_task",
      label: "Delegate Task to Subagent",
      description:
        "Spawn a sub-agent to handle a self-contained task. " +
        "When running inside tmux, the subagent opens in a visible split pane so you can watch it work. " +
        "Otherwise runs headless. The subagent gets its own isolated context (no conversation history). " +
        "Use for parallel work, research tasks, or when you need a fresh perspective. " +
        "The subagent can read and write files but cannot see the parent's conversation.",
      parameters: Type.Object({
        prompt: Type.String({
          description: "The task description to send to the sub-agent. Include all necessary context.",
        }),
        working_directory: Type.Optional(
          Type.String({
            description: "Directory the subagent should work in. Defaults to CWD.",
          }),
        ),
        model: Type.Optional(
          Type.String({
            description: "Model for the subagent (e.g., 'sonnet', 'opus', 'glm'). Defaults to current model.",
          }),
        ),
        files: Type.Optional(
          Type.Array(
            Type.String({ description: "File path to include as context." }),
          ),
          { description: "Files to @-include in the subagent's prompt." },
        ),
        mode: Type.Optional(
          Type.Union([Type.Literal("split"), Type.Literal("window"), Type.Literal("background")], {
            description: "'split' = side-by-side pane (default), 'window' = new tmux tab, 'background' = headless. Ignored if not in tmux.",
          }),
        ),
        timeout: Type.Optional(
          Type.Number({
            description: "Timeout in seconds. Default 180.",
          }),
        ),
      }),
      promptGuidelines: [
        "Use delegate_task for tasks that can be done independently without conversation context.",
        "Provide all necessary context in the prompt — the subagent starts fresh with no history.",
        "Include file paths in the files parameter if the subagent needs to read specific files.",
        "For tmux users: the subagent runs in a visible split pane by default. Use mode='background' for hidden execution.",
        "Multiple delegate_task calls in the same turn run in parallel — each gets its own pane.",
        "Always check the subagent's output and verify results before proceeding.",
      ],
      async execute(_toolCallId, params, signal, onUpdate, ctx) {
        const cwd = params.working_directory ?? ctx.cwd;
        const timeout = (params.timeout ?? 180) * 1000;
        const files = params.files ?? [];
        const useTmux = isInTmux() && params.mode !== "background";

        // Notify user
        ctx.ui.setWorkingMessage(`Subagent working${useTmux ? " (tmux pane)" : " (headless)"}...`);

        let result: { output: string; stderr: string; exitCode: number };

        if (useTmux) {
          result = await runTmuxSubagent(params.prompt, cwd, {
            model: params.model,
            files,
            mode: params.mode === "window" ? "window" : "split",
            timeout,
          }, signal);
        } else {
          result = await runHeadlessSubagent(params.prompt, cwd, {
            model: params.model,
            files,
            timeout,
          }, signal);
        }

        ctx.ui.setWorkingMessage();

        const output = truncateOutput(result.output || "(subagent returned no output)");
        const parts: Array<{ type: "text"; text: string }> = [
          { type: "text", text: output },
        ];

        if (result.exitCode !== 0) {
          parts.push({
            type: "text",
            text: `\n⚠ Subagent exited with code ${result.exitCode}`,
          });
        }

        if (result.stderr) {
          parts.push({
            type: "text",
            text: `\nStderr:\n${truncateOutput(result.stderr)}`,
          });
        }

        return { content: parts };
      },
    }),
  );

  // /delegate command — interactive shortcut
  pi.registerCommand("delegate", {
    description: "Delegate a task to a sub-agent (opens in tmux pane if available)",
    async handler(args, ctx) {
      const task = (args ?? "").trim();
      if (!task) {
        ctx.ui.notify("Usage: /delegate <task description>", "info");
        return;
      }
      // Paste a delegate_task tool call into the editor so the agent picks it up
      ctx.ui.pasteToEditor(
        `Use the delegate_task tool with this prompt: ${task}`,
      );
    },
  });
}
