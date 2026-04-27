/**
 * Git Checkpoint Extension for pi-coding-agent.
 *
 * Automatically creates lightweight git checkpoints (tags) at key moments
 * during a coding session, allowing the agent (or user) to roll back to
 * known-good states.
 *
 * Checkpoints are created as git tags with the prefix `pi-checkpoint-`.
 * The agent can list, diff, and restore checkpoints via registered tools.
 *
 * Configuration in options.nix:
 *   programs.aiAgents.pi.gitCheckpoint.enable = true;
 */
import { Type } from "@mariozechner/pi-ai";
import { defineTool, type ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

const CHECKPOINT_PREFIX = "pi-checkpoint-";

async function git(args: string[], cwd: string): Promise<{ stdout: string; stderr: string }> {
  return execFileAsync("git", args, { cwd, maxBuffer: 5 * 1024 * 1024 });
}

async function isGitRepo(cwd: string): Promise<boolean> {
  try {
    await git(["rev-parse", "--git-dir"], cwd);
    return true;
  } catch {
    return false;
  }
}

function makeTagName(label: string): string {
  const sanitized = label.replace(/[^a-zA-Z0-9_-]/g, "-").slice(0, 60);
  const ts = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
  return `${CHECKPOINT_PREFIX}${ts}-${sanitized}`;
}

export default function (pi: ExtensionAPI): void {
  // --- Tool: create_checkpoint ---
  pi.registerTool(
    defineTool({
      name: "create_checkpoint",
      label: "Create Git Checkpoint",
      description:
        "Create a git checkpoint (lightweight tag) at the current HEAD. " +
        "Use before making risky changes so you can roll back if needed.",
      parameters: Type.Object({
        label: Type.String({
          description: "Short descriptive label for this checkpoint (e.g., 'before-refactor', 'pre-test-fix').",
        }),
        message: Type.Optional(
          Type.String({
            description: "Optional longer message describing the checkpoint.",
          }),
        ),
      }),
      promptGuidelines: [
        "Create a checkpoint before making significant changes to the codebase.",
        "Use descriptive labels like 'before-refactor' or 'pre-database-migration'.",
      ],
      async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
        if (!(await isGitRepo(ctx.cwd))) {
          return {
            content: [{ type: "text" as const, text: "Not a git repository — cannot create checkpoint." }],
          };
        }

        // Stage and commit any pending changes first
        const status = await git(["status", "--porcelain"], ctx.cwd);
        if (status.stdout.trim()) {
          await git(["add", "-A"], ctx.cwd);
          await git(["commit", "-m", `chore(pi): checkpoint: ${params.label}`], ctx.cwd);
        }

        const tagName = makeTagName(params.label);
        const tagArgs = params.message
          ? ["tag", "-a", tagName, "-m", params.message]
          : ["tag", tagName];
        await git(tagArgs, ctx.cwd);

        const commitHash = (await git(["rev-parse", "--short", "HEAD"], ctx.cwd)).stdout.trim();
        return {
          content: [{
            type: "text" as const,
            text: `Checkpoint created: ${tagName} at ${commitHash}`,
          }],
        };
      },
    }),
  );

  // --- Tool: list_checkpoints ---
  pi.registerTool(
    defineTool({
      name: "list_checkpoints",
      label: "List Git Checkpoints",
      description: "List all pi-managed git checkpoints in the repository.",
      parameters: Type.Object({}),
      async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
        if (!(await isGitRepo(ctx.cwd))) {
          return {
            content: [{ type: "text" as const, text: "Not a git repository." }],
          };
        }

        const { stdout } = await git(
          ["tag", "-l", `${CHECKPOINT_PREFIX}*`, "--sort=-creatordate"],
          ctx.cwd,
        );

        const tags = stdout.trim();
        if (!tags) {
          return {
            content: [{ type: "text" as const, text: "No checkpoints found." }],
          };
        }

        // Get details for each tag
        const lines = tags.split("\n").slice(0, 20); // cap at 20
        const details = await Promise.all(
          lines.map(async (tag) => {
            try {
              const hash = (await git(["rev-list", "-1", "--short", tag], ctx.cwd)).stdout.trim();
              const date = (await git(["log", "-1", "--format=%ci", tag], ctx.cwd)).stdout.trim();
              return `${tag}  (${hash}, ${date})`;
            } catch {
              return tag;
            }
          }),
        );

        return {
          content: [{ type: "text" as const, text: details.join("\n") }],
        };
      },
    }),
  );

  // --- Tool: restore_checkpoint ---
  pi.registerTool(
    defineTool({
      name: "restore_checkpoint",
      label: "Restore Git Checkpoint",
      description:
        "Restore the working tree to a previously created checkpoint. " +
        "WARNING: this will discard uncommitted changes. Creates a backup tag first.",
      parameters: Type.Object({
        tag: Type.String({
          description: "The checkpoint tag name to restore (from list_checkpoints).",
        }),
        discard_uncommitted: Type.Optional(
          Type.Boolean({
            description: "If true, discard uncommitted changes. Default: false (abort if dirty).",
          }),
        ),
      }),
      promptGuidelines: [
        "Always list checkpoints first to confirm the correct tag.",
        "Be cautious when restoring — this changes the working tree.",
      ],
      async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
        if (!(await isGitRepo(ctx.cwd))) {
          return {
            content: [{ type: "text" as const, text: "Not a git repository." }],
          };
        }

        // Check for dirty working tree
        const status = await git(["status", "--porcelain"], ctx.cwd);
        if (status.stdout.trim() && !params.discard_uncommitted) {
          return {
            content: [{
              type: "text" as const,
              text: "Working tree has uncommitted changes. Set discard_uncommitted=true to proceed, or commit/stash first.",
            }],
          };
        }

        // Create a backup tag before restoring
        const backupTag = `${params.tag}-pre-restore-${Date.now()}`;
        await git(["tag", backupTag], ctx.cwd).catch(() => { /* no-op if HEAD hasn't moved */ });

        // Restore
        await git(["checkout", params.tag], ctx.cwd);
        return {
          content: [{
            type: "text" as const,
            text: `Restored to ${params.tag}. Backup tag: ${backupTag}\nNote: you are now in detached HEAD. Create a branch if needed.`,
          }],
        };
      },
    }),
  );

  // --- Lifecycle: auto-checkpoint on session start ---
  pi.on("session_start", async (_event, ctx) => {
    if (!(await isGitRepo(ctx.cwd))) return;
    const status = await git(["status", "--porcelain"], ctx.cwd);
    if (status.stdout.trim()) {
      // Auto-checkpoint dirty state at session start
      try {
        await git(["add", "-A"], ctx.cwd);
        await git(["commit", "-m", "chore(pi): auto-checkpoint at session start"], ctx.cwd);
        const tag = makeTagName("session-start");
        await git(["tag", tag], ctx.cwd);
      } catch {
        // Commit might fail if nothing to commit (race), ignore
      }
    }
  });
}
