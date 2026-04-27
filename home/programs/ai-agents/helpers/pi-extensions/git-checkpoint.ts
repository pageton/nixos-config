/**
 * Git Checkpoint Extension for pi-coding-agent.
 *
 * Creates checkpoint BRANCHES (never tags, never commits on the user's branch).
 * Dirty working tree state is captured into the checkpoint branch via stash,
 * leaving the user's original branch untouched.
 *
 * Flow:
 *   create_checkpoint("before-refactor")
 *     1. stash dirty changes
 *     2. create branch pi-cp/<timestamp>-before-refactor from clean HEAD
 *     3. pop stash on checkpoint branch, commit there
 *     4. switch back to original branch (still clean at the same HEAD)
 *
 *   restore_checkpoint("pi-cp/...")
 *     1. merge or checkout the checkpoint branch
 *     2. user's branch gets the checkpoint state
 *
 * Configuration in options.nix:
 *   programs.aiAgents.pi.gitCheckpoint.enable = true;
 */
import { Type } from "@mariozechner/pi-ai";
import { defineTool, type ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

const BRANCH_PREFIX = "pi-cp/";

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

async function currentBranch(cwd: string): Promise<string> {
  const { stdout } = await git(["rev-parse", "--abbrev-ref", "HEAD"], cwd);
  return stdout.trim();
}

function makeBranchName(label: string): string {
  const sanitized = label.replace(/[^a-zA-Z0-9_-]/g, "-").slice(0, 60);
  const ts = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
  return `${BRANCH_PREFIX}${ts}-${sanitized}`;
}

export default function (pi: ExtensionAPI): void {
  // --- Tool: create_checkpoint ---
  pi.registerTool(
    defineTool({
      name: "create_checkpoint",
      label: "Create Git Checkpoint",
      description:
        "Create a git checkpoint branch from the current state. " +
        "Dirty working tree changes are captured into the checkpoint branch. " +
        "The user's current branch is NEVER modified — no commits, no tags. " +
        "Use before making risky changes so you can roll back if needed.",
      parameters: Type.Object({
        label: Type.String({
          description: "Short descriptive label (e.g., 'before-refactor', 'pre-test-fix').",
        }),
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

        const originalBranch = await currentBranch(ctx.cwd);
        const branchName = makeBranchName(params.label);
        const status = await git(["status", "--porcelain"], ctx.cwd);
        const isDirty = status.stdout.trim().length > 0;

        if (isDirty) {
          // Stash dirty changes
          await git(["stash", "push", "--include-untracked", "-m", `checkpoint: ${params.label}`], ctx.cwd);
        }

        // Create checkpoint branch from current (clean) HEAD
        await git(["branch", branchName], ctx.cwd);

        if (isDirty) {
          // Switch to checkpoint branch, pop stash, commit there
          await git(["checkout", branchName], ctx.cwd);
          await git(["stash", "pop"], ctx.cwd);
          await git(["add", "-A"], ctx.cwd);
          try {
            await git(["commit", "-m", `chore(pi): checkpoint: ${params.label}`], ctx.cwd);
          } catch {
            // Nothing to commit (stash was empty or same as HEAD) — that's fine
          }
          // Switch back to original branch
          await git(["checkout", originalBranch], ctx.cwd);
        }

        const commitHash = (await git(["rev-parse", "--short", branchName], ctx.cwd)).stdout.trim();
        const summary = isDirty
          ? `Checkpoint branch: ${branchName} (${commitHash}) — dirty state captured`
          : `Checkpoint branch: ${branchName} (${commitHash}) — clean HEAD snapshot`;

        return {
          content: [{ type: "text" as const, text: summary }],
        };
      },
    }),
  );

  // --- Tool: list_checkpoints ---
  pi.registerTool(
    defineTool({
      name: "list_checkpoints",
      label: "List Git Checkpoints",
      description: "List all pi-managed checkpoint branches in the repository.",
      parameters: Type.Object({}),
      async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
        if (!(await isGitRepo(ctx.cwd))) {
          return {
            content: [{ type: "text" as const, text: "Not a git repository." }],
          };
        }

        const { stdout } = await git(
          ["branch", "--list", `${BRANCH_PREFIX}*`, "--sort=-creatordate", "--format=%(refname:short) %(objectname:short) %(creatordate:short)"],
          ctx.cwd,
        );

        const branches = stdout.trim();
        if (!branches) {
          return {
            content: [{ type: "text" as const, text: "No checkpoints found." }],
          };
        }

        return {
          content: [{ type: "text" as const, text: branches }],
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
        "Restore the working tree to a previously created checkpoint branch. " +
        "Merges the checkpoint into the current branch. " +
        "Creates a pre-restore checkpoint branch first for safety.",
      parameters: Type.Object({
        branch: Type.String({
          description: "The checkpoint branch name to restore (from list_checkpoints).",
        }),
        strategy: Type.Optional(
          Type.String({
            description: "Restore strategy: 'merge' (default, safe) or 'checkout' (replace working tree).",
          }),
        ),
      }),
      promptGuidelines: [
        "Always list checkpoints first to confirm the correct branch name.",
        "Prefer 'merge' strategy — it's safer and preserves history.",
      ],
      async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
        if (!(await isGitRepo(ctx.cwd))) {
          return {
            content: [{ type: "text" as const, text: "Not a git repository." }],
          };
        }

        const branch = params.branch;
        const strategy = params.strategy || "merge";

        // Verify the checkpoint branch exists
        try {
          await git(["rev-parse", "--verify", branch], ctx.cwd);
        } catch {
          return {
            content: [{ type: "text" as const, text: `Checkpoint branch '${branch}' not found. Run list_checkpoints first.` }],
          };
        }

        // Create a safety checkpoint before restoring
        const restoreBranch = await currentBranch(ctx.cwd);
        const preRestoreBranch = `${BRANCH_PREFIX}pre-restore-${Date.now()}`;
        await git(["branch", preRestoreBranch], ctx.cwd).catch(() => { /* no-op */ });

        if (strategy === "checkout") {
          // Full checkout — switches to checkpoint branch
          await git(["checkout", branch], ctx.cwd);
          return {
            content: [{
              type: "text" as const,
              text: `Checked out ${branch}. Safety branch: ${preRestoreBranch}\nYou are now on the checkpoint branch. Merge or cherry-pick as needed.`,
            }],
          };
        }

        // Default: merge into current branch
        try {
          await git(["merge", branch, "--no-edit"], ctx.cwd);
          return {
            content: [{
              type: "text" as const,
              text: `Merged ${branch} into ${currentBranch}. Safety branch: ${preRestoreBranch}`,
            }],
          };
        } catch (e: any) {
          return {
            content: [{
              type: "text" as const,
              text: `Merge conflict detected. Resolve manually or use strategy='checkout'. Safety branch: ${preRestoreBranch}\nError: ${e.message || e}`,
            }],
          };
        }
      },
    }),
  );

  // --- Tool: diff_checkpoint ---
  pi.registerTool(
    defineTool({
      name: "diff_checkpoint",
      label: "Diff Git Checkpoint",
      description: "Show what changed between a checkpoint branch and the current HEAD.",
      parameters: Type.Object({
        branch: Type.String({
          description: "The checkpoint branch name to diff against (from list_checkpoints).",
        }),
      }),
      async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
        if (!(await isGitRepo(ctx.cwd))) {
          return {
            content: [{ type: "text" as const, text: "Not a git repository." }],
          };
        }

        try {
          const { stdout } = await git(["diff", "--stat", params.branch, "HEAD"], ctx.cwd);
          return {
            content: [{ type: "text" as const, text: stdout || "No differences." }],
          };
        } catch (e: any) {
          return {
            content: [{ type: "text" as const, text: `Failed to diff: ${e.message || e}` }],
          };
        }
      },
    }),
  );

  // --- Tool: delete_checkpoint ---
  pi.registerTool(
    defineTool({
      name: "delete_checkpoint",
      label: "Delete Git Checkpoint",
      description: "Delete a checkpoint branch. Only deletes pi-managed branches (pi-cp/* prefix).",
      parameters: Type.Object({
        branch: Type.String({
          description: "The checkpoint branch name to delete (from list_checkpoints).",
        }),
      }),
      async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
        if (!(await isGitRepo(ctx.cwd))) {
          return {
            content: [{ type: "text" as const, text: "Not a git repository." }],
          };
        }

        if (!params.branch.startsWith(BRANCH_PREFIX)) {
          return {
            content: [{ type: "text" as const, text: `Refusing to delete non-checkpoint branch: ${params.branch}` }],
          };
        }

        try {
          await git(["branch", "-D", params.branch], ctx.cwd);
          return {
            content: [{ type: "text" as const, text: `Deleted checkpoint: ${params.branch}` }],
          };
        } catch (e: any) {
          return {
            content: [{ type: "text" as const, text: `Failed to delete: ${e.message || e}` }],
          };
        }
      },
    }),
  );

  // --- Lifecycle: auto-checkpoint on session start (branch-based, no commits on user branch) ---
  pi.on("session_start", async (_event, ctx) => {
    if (!(await isGitRepo(ctx.cwd))) return;
    const status = await git(["status", "--porcelain"], ctx.cwd);
    if (status.stdout.trim()) {
      try {
        const originalBranch = await currentBranch(ctx.cwd);
        const branchName = makeBranchName("session-start");
        await git(["stash", "push", "--include-untracked", "-m", "checkpoint: session-start"], ctx.cwd);
        await git(["branch", branchName], ctx.cwd);
        await git(["checkout", branchName], ctx.cwd);
        await git(["stash", "pop"], ctx.cwd);
        await git(["add", "-A"], ctx.cwd);
        try {
          await git(["commit", "-m", "chore(pi): auto-checkpoint at session start"], ctx.cwd);
        } catch { /* nothing to commit */ }
        await git(["checkout", originalBranch], ctx.cwd);
      } catch {
        // Best-effort — don't block session start
      }
    }
  });
}
