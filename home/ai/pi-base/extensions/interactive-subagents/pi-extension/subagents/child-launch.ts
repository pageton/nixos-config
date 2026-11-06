import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
// headlessActive comes through the surface seam (tmux.ts) so offline fixtures
// control the dispatch mode consistently with the rest of the surface layer.
import { headlessActive, shellEscape } from "./tmux.ts";
import type { HeadlessSpawn } from "./headless.ts";
import { writeSubagentLoadout, type SubagentLoadout } from "./session.ts";
import type { LaunchPlan, RunningSubagent } from "./managed-run.ts";
import {
  currentProfilePolicy,
  COMMON_CHILD_TOOLS,
  COMMON_EXTENSION_TOOLS,
} from "./profile-policy.ts";

export interface AgentDefaults {
  model?: string;
  tools?: string;
  skills?: string;
  thinking?: string;
  /** Presence grants spawning, constrained by PI_SUBAGENT_ALLOWED. */
  subagentAgents?: string[];
  autoExit?: boolean;
  interactive?: boolean;
  systemPromptMode?: "append" | "replace";
  sessionMode?: "standalone" | "lineage-only" | "fork";
  cwd?: string;
  cli?: string;
  body?: string;
  disableModelInvocation?: boolean;
}

type LaunchRequest =
  | {
      kind: "initial";
      profile: AgentDefaults | null;
      model?: string;
      thinking?: string;
      cwd: string | null;
      agentDir: string | null;
    }
  | { kind: "resume"; loadout: SubagentLoadout };

/** Shared with tool-extension registration so grants and backing paths agree. */
export const SPAWNING_TOOLS = ["subagent", "subagent_message", "subagents_list"] as const;

function toolAllowlist(tools: string | undefined, spawnable: string[] | undefined): string | null {
  const requested = (tools ?? "")
    .split(",")
    .map((tool) => tool.trim())
    .filter(Boolean);
  const grantSpawning = !!spawnable?.length;
  if (!requested.length && !grantSpawning) return null;
  const allow = new Set(requested);
  if (grantSpawning) for (const tool of SPAWNING_TOOLS) allow.add(tool);
  allow.add("ask_question");
  return [...allow].join(",");
}

function safeName(name: string, fallback: string): string {
  return (
    name
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, "")
      .replace(/\s+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-|-$/g, "") || fallback
  );
}

function timestamp(): string {
  return new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
}

function writeArtifact(file: string, content: string): string {
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, content, "utf8");
  return file;
}

/** Prepare initial and resumed commands behind one sandbox/handoff interface.
 * The caller supplies resolved profile/path facts, never assembles CLI policy.
 * ManagedRuns invokes this only after claiming the session; it still owns
 * registration, writer fencing, dispatch and supervision.
 */
/** Shared with managed-run so typed and native dispatch build the same env. */
export function subagentEnvironment(
  loadout: SubagentLoadout,
  running: RunningSubagent,
  autoExit: boolean,
): Record<string, string | undefined> {
  return {
    PI_CODING_AGENT_DIR:
      loadout.profilePolicy?.agentDir ?? loadout.agentDir ?? process.env.PI_CODING_AGENT_DIR,
    PI_PROFILE: loadout.profilePolicy?.profile ?? "pi-coding",
    PI_BASE_CHILD_POLICY: loadout.profilePolicy ? JSON.stringify(loadout.profilePolicy) : "",
    PI_CODING_AGENT_SESSION_DIR: loadout.profilePolicy?.sessions ?? "",
    PI_SUBAGENT_ALLOWED: loadout.spawnable?.length ? loadout.spawnable.join(",") : undefined,
    PI_SUBAGENT_AGENT: loadout.agent ?? undefined,
    PI_SUBAGENT_NAME: running.name,
    PI_SUBAGENT_SESSION: running.sessionFile,
    PI_SUBAGENT_ID: running.id,
    PI_SUBAGENT_WRITER_TOKEN: undefined, // the owning runtime supplies it at dispatch
    PI_SUBAGENT_ACTIVITY_FILE: running.activityFile,
    PI_SUBAGENT_AUTO_EXIT: autoExit ? "1" : undefined,
  };
}

export class ChildLaunch {
  constructor(
    private readonly subagentsDir: string,
    private readonly toolExtensionPath: (tool: string) => string | undefined,
  ) {}

  prepare(request: LaunchRequest, running: RunningSubagent): LaunchPlan {
    if (request.kind === "initial" && request.profile?.cli === "claude") {
      if (currentProfilePolicy()) {
        throw new Error(
          "Explicit-load domain subagents require Pi; use pi-coding for Claude roles",
        );
      }
      return this.claude(request, running);
    }
    return this.pi(request, running);
  }

  private claude(
    request: Extract<LaunchRequest, { kind: "initial" }>,
    running: RunningSubagent,
  ): LaunchPlan {
    const parts = [
      `PI_CLAUDE_SENTINEL=${shellEscape(running.sentinelFile!)}`,
      "claude",
      "--dangerously-skip-permissions",
    ];
    const plugin = join(this.subagentsDir, "plugin");
    if (existsSync(plugin)) parts.push("--plugin-dir", shellEscape(plugin));
    const model = request.model ?? request.profile?.model;
    if (model) parts.push("--model", shellEscape(model));
    if (request.profile?.body)
      parts.push("--append-system-prompt", shellEscape(request.profile.body));
    // Claude always receives the caller's task directly, not Pi's wrapper.
    parts.push(shellEscape(running.task));
    return {
      kind: "command",
      command: `${request.cwd ? `cd ${shellEscape(request.cwd)} && ` : ""}${parts.join(" ")}`,
      launchScriptFile: join(
        running.parentArtifactDir,
        "subagent-scripts",
        `${safeName(running.name, "subagent")}-${running.id}.sh`,
      ),
      scriptPreamble: [
        `# Claude Code subagent launch script for ${running.name}`,
        `# Generated: ${new Date().toISOString()}`,
        `# Surface: ${running.surface}`,
      ].join("\n"),
    };
  }

  private sandbox(
    parts: string[],
    loadout: SubagentLoadout,
    running: RunningSubagent,
    esc: (value: string) => string = shellEscape,
  ): void {
    if (loadout.model) parts.push("--model", esc(loadout.model));
    if (loadout.thinking) parts.push("--thinking", esc(loadout.thinking));
    const policy = loadout.profilePolicy;
    if (policy) {
      parts.push(
        "--no-context-files",
        "--no-skills",
        "--no-prompt-templates",
        "--no-themes",
        "--offline",
        "--no-mcp",
      );
      const instructions = policy.instructions.map((file) => readFileSync(file, "utf8"));
      if (loadout.identity && loadout.systemPromptMode !== "replace")
        instructions.push(loadout.identity);
      const file = writeArtifact(
        join(running.parentArtifactDir, `context/${running.id}-profile.md`),
        instructions.join("\n\n"),
      );
      parts.push("--append-system-prompt", esc(file));
      for (const skill of policy.skills) parts.push("--skill", esc(skill));
      for (const extension of policy.extensions) parts.push("-e", esc(extension));
    }
    if (
      (loadout.toolAllowlist || policy) &&
      (loadout.model?.startsWith("opencode-cli/") || loadout.model?.startsWith("kilo-free/"))
    ) {
      // Provider registration is not a tool grant. Restricted coding children
      // disable discovery; older explicit-load snapshots may also lack it.
      const provider = join(
        this.subagentsDir,
        loadout.model.startsWith("opencode-cli/")
          ? "../../../opencode-cli/index.ts"
          : "../../../our-free-model.ts",
      );
      if (!existsSync(provider))
        throw new Error("The free-model provider extension is missing; refusing a fallback model.");
      if (!policy?.extensions.includes(provider)) parts.push("-e", esc(provider));
    }
    if (loadout.identity && (!policy || loadout.systemPromptMode === "replace")) {
      const flag =
        loadout.systemPromptMode === "replace" ? "--system-prompt" : "--append-system-prompt";
      const file = writeArtifact(
        join(
          running.parentArtifactDir,
          `context/${safeName(running.name, "subagent")}-sysprompt-${timestamp()}.md`,
        ),
        loadout.identity,
      );
      parts.push(flag, esc(file));
    }
    // A null allowlist deliberately preserves unrestricted launches/resumes.
    if (loadout.toolAllowlist) {
      parts.push("--no-extensions", "--tools", esc(loadout.toolAllowlist));
      const extensions = new Set<string>();
      if (!policy) {
        // Restricted coding children disable discovery, so a provider-only
        // extension cannot be recovered through toolExtensionPath. Load the
        // transport shim from this same bundle without granting another tool.
        // Explicit-load profiles already replay their pinned extension policy.
        const transport = join(this.subagentsDir, "../../../codex-lb-session.ts");
        if (existsSync(transport)) extensions.add(transport);
      }
      for (const tool of loadout.toolAllowlist.split(",")) {
        if (policy && COMMON_EXTENSION_TOOLS.has(tool)) continue;
        const file = this.toolExtensionPath(tool);
        if (file && existsSync(file)) extensions.add(file);
      }
      for (const file of extensions) parts.push("-e", esc(file));
    }
  }

  private pi(request: LaunchRequest, running: RunningSubagent): LaunchPlan {
    const profile = request.kind === "initial" ? request.profile : null;
    const identity = profile?.body ?? null;
    const identityInSystemPrompt = profile?.systemPromptMode && identity;
    const policy =
      request.kind === "resume" ? request.loadout.profilePolicy : currentProfilePolicy();
    const loadout: SubagentLoadout =
      request.kind === "resume"
        ? request.loadout
        : {
            agent: running.agent ?? null,
            toolAllowlist:
              toolAllowlist(profile?.tools, profile?.subagentAgents) ??
              (policy ? COMMON_CHILD_TOOLS.join(",") : null),
            ...(policy ? { profilePolicy: policy } : {}),
            model: request.model ?? profile?.model ?? null,
            thinking: request.thinking ?? profile?.thinking ?? null,
            systemPromptMode: profile?.systemPromptMode ?? null,
            identity: identityInSystemPrompt ? identity : null,
            spawnable: profile?.subagentAgents ?? null,
            autoExit: profile?.autoExit ?? false,
            cwd: request.cwd,
            agentDir: request.agentDir,
          };
    if (request.kind === "initial") writeSubagentLoadout(running.sessionFile, loadout);
    const subagentDone = join(this.subagentsDir, "subagent-done.ts");
    const parts = [
      policy ? shellEscape(policy.pi) : "pi",
      policy ? "--no-approve" : "--approve",
      "--session",
      shellEscape(running.sessionFile),
      "-e",
      shellEscape(subagentDone),
    ];
    this.sandbox(parts, loadout, running);
    // The same argv without shell escaping feeds the native (headless) spawn.
    const rawArgs = [
      policy ? policy.pi : "pi",
      policy ? "--no-approve" : "--approve",
      "--session",
      running.sessionFile,
      "-e",
      subagentDone,
    ];
    this.sandbox(rawArgs, loadout, running, (value) => value);
    const resume = request.kind === "resume";
    // Without a pane nobody can drive a parked session: native children always
    // settle and exit; follow-ups resume the session instead.
    const autoExit = headlessActive() || resume || (profile?.autoExit ?? false);

    let resumeMsgFile: string | undefined;
    let initialPrompt: string | null = null;
    let skillNames: string[] = [];
    if (request.kind === "resume") {
      if (running.task) {
        resumeMsgFile = writeArtifact(
          join(
            running.parentArtifactDir,
            "subagent-resume",
            `${safeName(running.name, "resume")}-${timestamp()}.md`,
          ),
          running.task,
        );
        parts.push(shellEscape(`@${resumeMsgFile}`));
        initialPrompt = running.task;
      }
    } else {
      const direct = profile?.sessionMode === "fork";
      const modeHint = autoExit
        ? "Complete your task autonomously. When you are finished, simply stop — your session ends automatically."
        : "Complete your task. The user can interact with you at any time, and the session ends when the user exits the pane.";
      const summaryInstruction = profile?.autoExit
        ? "Your FINAL assistant message should summarize what you accomplished."
        : "Your FINAL assistant message (before the user exits) should summarize what you accomplished.";
      const roleBlock = identity && !identityInSystemPrompt ? `\n\n${identity}` : "";
      const fullTask = direct
        ? running.task
        : `${roleBlock}\n\n${modeHint}\n\n${running.task}\n\n${summaryInstruction}`;
      const taskArg = direct
        ? fullTask
        : `@${writeArtifact(
            join(
              running.parentArtifactDir,
              `context/${safeName(running.name, "subagent")}-${timestamp()}.md`,
            ),
            fullTask,
          )}`;
      initialPrompt = direct ? running.task : fullTask;
      skillNames = (profile?.skills ?? "")
        .split(",")
        .map((skill) => skill.trim())
        .filter(Boolean);
      const skills = skillNames.map((skill) => `/skill:${skill}`);
      // Pi concatenates @file with messages[0]. Keep /skill: in separate
      // follow-ups for blank sessions so the child's skill expansion works.
      for (const arg of [...(!direct && skills.length ? [""] : []), ...skills, taskArg]) {
        parts.push(shellEscape(arg));
      }
    }
    const headlessSpawn: HeadlessSpawn | undefined = headlessActive()
      ? {
          file: rawArgs[0]!,
          args: [
            ...rawArgs.slice(1),
            "--mode",
            "rpc",
            ...skillNames.flatMap((skill) => ["--skill", skill]),
          ],
          env: subagentEnvironment(loadout, running, autoExit),
          cwd: loadout.cwd,
          initialPrompt,
          scriptFile: join(
            running.parentArtifactDir,
            "subagent-scripts",
            resume
              ? `${safeName(running.name, "resume")}-resume-${Date.now()}.sh`
              : `${safeName(running.name, "subagent")}-${running.id}.sh`,
          ),
          scriptPreamble: [
            `# Subagent ${resume ? "resume" : "launch"} (native) for ${running.name}`,
            `# Generated: ${new Date().toISOString()}`,
            `# Session: ${running.sessionFile}`,
            ...(resumeMsgFile ? [`# Resume message file: ${resumeMsgFile}`] : []),
          ].join("\n"),
        }
      : undefined;
    return {
      kind: "pi",
      parts,
      loadout,
      // Resumes always run autonomously, independent of the saved initial policy.
      autoExit,
      headlessSpawn,
      launchScriptFile:
        headlessSpawn?.scriptFile ??
        join(
          running.parentArtifactDir,
          "subagent-scripts",
          resume
            ? `${safeName(running.name, "resume")}-resume-${Date.now()}.sh`
            : `${safeName(running.name, "subagent")}-${running.id}.sh`,
      ),
      scriptPreamble: [
        `# Subagent ${resume ? "resume" : "launch"} script for ${running.name}`,
        `# Generated: ${new Date().toISOString()}`,
        `# Session: ${running.sessionFile}`,
        `# Surface: ${running.surface}`,
        ...(resumeMsgFile ? [`# Resume message file: ${resumeMsgFile}`] : []),
      ].join("\n"),
    };
  }
}
