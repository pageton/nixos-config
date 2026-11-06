/**
 * Headless surface: native pi subprocesses for hosts that embed pi without a
 * terminal multiplexer (t3-code, ThinkRail, or a plain terminal outside
 * tmux/Herdr).
 *
 * Each subagent runs `pi --mode rpc` as a detached child in its own process
 * group; this extension acts as its RPC client — the initial task and later
 * steering arrive as `prompt` commands on the child's stdin pipe. Everything
 * the child prints is appended to a per-surface log file, and when the child
 * exits the supervisor appends the same `__SUBAGENT_DONE_<code>__` sentinel
 * the pane surfaces scrape, so the completion/evidence protocol is identical.
 *
 * Surfaces are `h<spawnerPid>-<seq>` ids; a small registry directory maps each
 * id to its child pid and log file so a restarted parent can still inspect or
 * close runs it adopted (reading logs and signalling work cross-process;
 * steering a child whose stdin pipe another process holds does not).
 */
import { spawn, type ChildProcess } from "node:child_process";
import {
  closeSync,
  mkdirSync,
  openSync,
  readFileSync,
  rmSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import { dirname, join } from "node:path";

/** True when no multiplexer owns this process and children must be native. */
export function headlessActive(): boolean {
  return !process.env.TMUX && process.env.HERDR_ENV !== "1";
}

export function isHeadlessSurface(surface: string): boolean {
  return /^h\d+-\d+$/.test(surface);
}

/** Stable per-boot identity: the same machineId/bootId the writer lease uses. */
export function headlessIdentity(): string {
  try {
    const machineId = readFileSync("/etc/machine-id", "utf8").trim();
    const bootId = readFileSync("/proc/sys/kernel/random/boot_id", "utf8").trim();
    return `headless:${machineId}:${bootId}`;
  } catch {
    throw new Error("Cannot establish the host identity for headless subagents");
  }
}

// ── Registry ──

function registryDirectory(): string {
  const uid = typeof process.getuid === "function" ? process.getuid() : -1;
  const dir = join(process.env.TMPDIR?.trim() || "/tmp", `pi-subagents-headless-${uid}`);
  mkdirSync(dir, { recursive: true, mode: 0o700 });
  return dir;
}

function registryFile(surface: string): string {
  return join(registryDirectory(), `${surface}.json`);
}

function logFile(surface: string): string {
  return join(registryDirectory(), `${surface}.log`);
}

interface RegistryEntry {
  /** Child pid; null between surface allocation and dispatch. */
  pid: number | null;
  logFile: string;
  startedAt: number;
}

function readRegistry(surface: string): RegistryEntry | undefined {
  try {
    return JSON.parse(readFileSync(registryFile(surface), "utf8"));
  } catch {
    return undefined;
  }
}

interface LiveChild {
  child: ChildProcess;
  stdin: NonNullable<ChildProcess["stdin"]>;
  logFile: string;
  exited: boolean;
}

/** In-process handles: only the spawning process can steer or await a child. */
const liveChildren = new Map<string, LiveChild>();

let surfaceCounter = 0;

/** Allocate a surface id and its registry stub; the child attaches at dispatch. */
export function createHeadlessSurface(name: string): string {
  void name;
  const surface = `h${process.pid}-${++surfaceCounter}`;
  const entry: RegistryEntry = { pid: null, logFile: logFile(surface), startedAt: Date.now() };
  writeFileSync(registryFile(surface), JSON.stringify(entry), { mode: 0o600 });
  return surface;
}

/** Structured spawn description produced by the launch planner. */
export interface HeadlessSpawn {
  file: string;
  args: string[];
  env: Record<string, string | undefined>;
  cwd: string | null;
  /** Initial task prompt sent over the RPC stdin pipe; null for command runs. */
  initialPrompt: string | null;
  /** Provenance script path kept next to the session artifacts. */
  scriptFile: string;
  scriptPreamble: string;
}

/**
 * Persist the equivalent shell script for auditability (the pane surfaces keep
 * the same artifact when they type their launch command).
 */
export function writeHeadlessScript(spawnPlan: HeadlessSpawn): void {
  mkdirSync(dirname(spawnPlan.scriptFile), { recursive: true });
  const envLines = Object.entries(spawnPlan.env)
    .filter((entry): entry is [string, string] => entry[1] !== undefined)
    .map(([key, value]) => `# ${key}=${value.replace(/\n/g, " ")}`)
    .join("\n");
  const body = [
    spawnPlan.scriptPreamble,
    "# Headless dispatch: this child is spawned directly, not typed into a pane.",
    envLines,
    `# cwd: ${spawnPlan.cwd ?? "(inherit)"}`,
    `exec ${[spawnPlan.file, ...spawnPlan.args].map((part) => JSON.stringify(part)).join(" ")}`,
    spawnPlan.initialPrompt === null ? "" : "# task delivered via the RPC stdin prompt",
  ]
    .filter((part) => part !== "")
    .join("\n");
  writeFileSync(spawnPlan.scriptFile, body + "\n", { mode: 0o755 });
}

/**
 * Spawn a headless child in its own process group with stdio logged to the
 * surface's log file, deliver the initial prompt, and arm the exit sentinel.
 */
export function spawnHeadlessChild(surface: string, plan: HeadlessSpawn): void {
  if (liveChildren.has(surface)) throw new Error(`Headless surface ${surface} already dispatched`);
  const file = logFile(surface);
  const out = openSync(file, "a");
  const child = spawn(plan.file, plan.args, {
    cwd: plan.cwd ?? undefined,
    env: cleanEnvironment(plan.env),
    detached: true, // own process group: survives the parent, group-signalable
    stdio: ["pipe", out, out],
  });
  child.unref();
  const stdin = child.stdin;
  if (!stdin) {
    rmSync(file, { force: true });
    throw new Error("Headless child spawned without an stdin pipe");
  }
  liveChildren.set(surface, { child, stdin, logFile: file, exited: false });
  const entry = readRegistry(surface);
  writeRegistry(surface, {
    pid: child.pid ?? null,
    logFile: file,
    startedAt: entry?.startedAt ?? Date.now(),
  });

  if (plan.initialPrompt !== null) {
    sendPrompt(stdin, plan.initialPrompt);
  }

  child.on("exit", (code) => {
    const live = liveChildren.get(surface);
    if (live) live.exited = true;
    // Terminal evidence for the shared poll protocol: same sentinel the panes use.
    try {
      const fd = openSync(file, "a");
      try {
        writeFileSync(fd, `__SUBAGENT_DONE_${code ?? 1}__\n`);
      } finally {
        closeFd(fd);
      }
    } catch {
      // The log is best-effort evidence; exit supervision also notices.
    }
    try {
      unlinkSync(registryFile(surface));
    } catch {
      // Another cleaner may have removed it already.
    }
  });
}

function closeFd(fd: number): void {
  try {
    closeSync(fd);
  } catch {}
}

function writeRegistry(surface: string, entry: RegistryEntry): void {
  writeFileSync(registryFile(surface), JSON.stringify(entry), { mode: 0o600 });
}

function cleanEnvironment(overlay: Record<string, string | undefined>) {
  const env = { ...process.env, ...overlay };
  for (const [key, value] of Object.entries(overlay)) {
    if (value === undefined) delete env[key];
  }
  // Same scrubbing the typed dispatch performs with `env -u`.
  for (const key of Object.keys(env)) {
    if (key.startsWith("PI_RE_")) delete env[key];
  }
  return env;
}

function sendPrompt(stdin: NonNullable<ChildProcess["stdin"]>, message: string): void {
  stdin.write(`${JSON.stringify({ type: "prompt", message })}\n`);
}

/**
 * Steer a running headless child by queueing another prompt on its RPC stdin.
 * Only the process that spawned the child holds the pipe; anything else fails
 * with a clear error instead of pretending the message was delivered.
 */
export function sendHeadlessCommand(surface: string, message: string): void {
  const live = liveChildren.get(surface);
  if (!live || live.exited || !live.child.stdin) {
    throw new Error(
      `Headless subagent ${surface} is not steerable from this session process ` +
        `(it was spawned elsewhere or has exited); wait for its result, then ` +
        `reply to resume it.`,
    );
  }
  sendPrompt(live.child.stdin, message);
}

/** Tail of the child's log: the headless equivalent of a screen capture. */
function tailLog(surface: string, lines: number): string {
  const entry = readRegistry(surface) ?? (liveChildren.get(surface) ? { logFile: logFile(surface), pid: null, startedAt: 0 } : undefined);
  if (!entry) throw new Error(`Headless surface ${surface} is not registered`);
  try {
    const content = readFileSync(entry.logFile, "utf8");
    return content.trimEnd().split("\n").slice(-Math.max(1, lines)).join("\n") + "\n";
  } catch {
    throw new Error(`Headless surface ${surface} has no readable log yet`);
  }
}

export function readHeadlessScreen(surface: string, lines = 50): string {
  return tailLog(surface, lines);
}

export async function readHeadlessScreenAsync(surface: string, lines = 50): Promise<string> {
  return tailLog(surface, lines);
}

function childAlive(pid: number): boolean {
  try {
    process.kill(-pid, 0); // negative: probe the whole process group
    return true;
  } catch {
    return false;
  }
}

export async function headlessSurfaceExists(surface: string): Promise<boolean> {
  const entry = readRegistry(surface);
  if (!entry) return false;
  if (entry.pid === null) return true; // allocated, dispatch pending
  return childAlive(entry.pid);
}

export function closeHeadlessSurface(surface: string): void {
  const entry = readRegistry(surface);
  const live = liveChildren.get(surface);
  if (live) {
    live.exited = true;
    try {
      live.child.kill("SIGTERM");
    } catch {}
    liveChildren.delete(surface);
  } else if (entry?.pid) {
    // A recalled run from another process: signal the detached group directly.
    try {
      process.kill(-entry.pid, "SIGTERM");
    } catch {}
  }
  try {
    unlinkSync(registryFile(surface));
  } catch {}
}
