/**
 * Surface layer: native Herdr panes inside Herdr, tmux splits inside tmux,
 * and otherwise a detached private tmux server (external hosts such as
 * t3-code or ThinkRail embed pi without any multiplexer environment).
 *
 * Everything the extension does to a pane goes through the small API in this
 * file: create/split a pane, type a command into it, read its screen, close
 * it, and establish presence. Completion protocol belongs to run-evidence.ts.
 * Keeping the tmux calls isolated here means index.ts
 * stays testable without a multiplexer running.
 *
 * Panes use backend-specific IDs (`%12` or `w1:p2`). Splits always target
 * the parent pi's pane, so they follow the agent rather than
 * the user's focus. In detached mode each subagent gets its own session in
 * the private server (there is no parent pane to split); humans can attach
 * with `tmux -L <socket> attach` at any time.
 */
import { execFile, execFileSync } from "node:child_process";
import { promisify } from "node:util";
import { writeFileSync, mkdirSync, existsSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import {
  isHerdrContext,
  herdrConfigured,
  herdrIdentity,
  isHerdrSurface,
  createHerdrSurface,
  createHerdrTab,
  sendHerdrCommand,
  readHerdrScreen,
  readHerdrScreenAsync,
  closeHerdrSurface,
  herdrSurfaceExists,
} from "./herdr.ts";

const execFileAsync = promisify(execFile);

// ── Availability ──

const commandAvailability = new Map<string, boolean>();

function hasCommand(command: string): boolean {
  if (commandAvailability.has(command)) {
    return commandAvailability.get(command)!;
  }

  let available = false;
  try {
    execFileSync("sh", ["-c", `command -v ${command}`], { stdio: "ignore" });
    available = true;
  } catch {
    available = false;
  }

  commandAvailability.set(command, available);
  return available;
}

/**
 * True when running inside tmux with the tmux binary on PATH.
 * `TMUX` is set by tmux in every process it spawns (shell or pane).
 */
export function isTmuxAvailable(): boolean {
  return !!process.env.TMUX && hasCommand("tmux");
}

// ── Detached private server ──

/** Socket name of the private tmux server used outside any multiplexer. */
const DETACHED_SOCKET_NAME = "pi-subagents";

/**
 * Directory tmux resolves `-L <name>` sockets in: `${TMUX_TMPDIR:-/tmp}/tmux-$uid`.
 * Mirrors tmux's own resolution so the identity stat matches the real endpoint.
 */
export function tmuxSocketDirectory(): string {
  const uid = typeof process.getuid === "function" ? process.getuid() : -1;
  return join(process.env.TMUX_TMPDIR?.trim() || "/tmp", `tmux-${uid}`);
}

/** Absolute socket path of the detached private server. */
export function detachedSocketPath(): string {
  return join(tmuxSocketDirectory(), DETACHED_SOCKET_NAME);
}

/**
 * True when no multiplexer owns this process but tmux can run subagents in a
 * detached private server. Hosts such as t3-code or ThinkRail embed pi without
 * TMUX/HERDR variables; Herdr still inherits the outer TMUX environment, so
 * it keeps priority via isHerdrContext().
 */
export function detachedActive(): boolean {
  return !process.env.TMUX && !isHerdrContext();
}

/** tmux argv prefix that addresses the detached server instead of the default one. */
function detachedArgs(args: string[]): string[] {
  return detachedActive() ? ["-L", DETACHED_SOCKET_NAME, ...args] : args;
}

/** How a human attaches to the detached subagent server. */
export function detachedAttachHint(): string {
  return `tmux -L ${DETACHED_SOCKET_NAME} attach`;
}

/**
 * Start the detached server once per process before its socket identity is
 * read. A named holder session keeps the server (and therefore the socket
 * inode the ownership fence binds to) alive across subagent churn. Concurrent
 * parents race harmlessly: the loser's duplicate-session error is fine once
 * any socket exists.
 */
let detachedServerEnsured = false;
export function ensureDetachedServer(): void {
  if (!detachedActive() || detachedServerEnsured) return;
  if (!existsSync(detachedSocketPath())) {
    mkdirSync(tmuxSocketDirectory(), { recursive: true });
    try {
      execFileSync(
        "tmux",
        detachedArgs([
          "new-session",
          "-d",
          "-s",
          "pi-holder",
          "-n",
          "holder",
          "-x",
          "80",
          "-y",
          "24",
          "exec sleep infinity",
        ]),
        { encoding: "utf8", stdio: "pipe", timeout: 5000 },
      );
    } catch (error) {
      // A concurrent parent may have created the server first; only fail if
      // the endpoint truly refused to appear.
      if (!existsSync(detachedSocketPath())) throw error;
    }
  }
  detachedServerEnsured = true;
}

export function isMuxAvailable(): boolean {
  // Herdr inherits the outer TMUX variables. Never fall through to that server.
  if (isHerdrContext()) return herdrConfigured() && hasCommand("herdr");
  // Inside tmux: split the caller's window. Outside: a detached server works
  // whenever the binary exists, so external hosts get subagents too.
  return hasCommand("tmux");
}

export function muxSetupHint(): string {
  return detachedActive()
    ? `Subagents need the tmux binary on PATH; inside a multiplexer start pi via \`tmux new -A -s pi 'pi'\`.`
    : "Start pi inside Herdr or tmux (`tmux new -A -s pi 'pi'`).";
}

export function muxIdentity(): string {
  if (isHerdrContext()) return herdrIdentity();
  if (detachedActive()) {
    // The private server's socket inode is the incarnation: a restarted
    // server gets a new inode and therefore never re-owns old panes.
    const stat = statSync(detachedSocketPath(), { bigint: true });
    if (!stat.isSocket()) throw new Error("Detached tmux endpoint is not a Unix socket");
    return `detachedtmux:${detachedSocketPath()}:${stat.dev}:${stat.ino}:${stat.ctimeNs}`;
  }
  // Preserve existing tmux owner identities; final field is the session, not server.
  return (process.env.TMUX ?? "").split(",").slice(0, 2).join(",");
}

export function isSurfaceId(surface: string): boolean {
  return isHerdrContext() ? isHerdrSurface(surface) : /^%\d+$/.test(surface);
}

function requireTmux(): void {
  if (!isMuxAvailable()) {
    throw new Error(`Herdr or tmux is required for subagents. ${muxSetupHint()}`);
  }
}

// ── Shell helpers ──

export function shellEscape(s: string): string {
  return "'" + s.replace(/'/g, "'\\''") + "'";
}

// ── Pane layout ──

/**
 * tmux layout applied to the subagent window to keep panes evenly sized.
 * Switchable: "even-horizontal" (equal columns, matches Ctrl+b Alt+1),
 * "main-vertical" (big main pane + tiled column), "tiled" (grid).
 */
const SUBAGENT_TMUX_LAYOUT = "even-horizontal";

let rebalanceTimer: ReturnType<typeof setTimeout> | null = null;

/**
 * Re-balance subagent panes so repeated splits don't leave them lopsided.
 * tmux halves the target pane on every split and dumps freed space onto a
 * neighbor on close, so without this panes drift to wildly uneven widths.
 * Applies SUBAGENT_TMUX_LAYOUT to the parent pi window. Debounced so a burst
 * of parallel spawns or staggered exits collapses into a single layout call,
 * and non-fatal: a cosmetic resize must never break spawning or watching.
 */
function rebalanceSurfaces(hintPane?: string): void {
  // Prefer the parent pi pane (stable; survives a closing subagent pane).
  if (isHerdrContext()) return; // Herdr owns its layout, not the inherited tmux window.
  if (detachedActive()) return; // Detached subagents are separate sessions; no shared window to balance.
  const target = process.env.TMUX_PANE ?? hintPane;
  if (!target) return;
  if (rebalanceTimer) clearTimeout(rebalanceTimer);
  rebalanceTimer = setTimeout(() => {
    rebalanceTimer = null;
    try {
      // -t <pane> resolves to that pane's window; does not change focus.
      execFileSync("tmux", ["select-layout", "-t", target, SUBAGENT_TMUX_LAYOUT], {
        encoding: "utf8",
      });
    } catch {
      // Pane/window may be gone; balancing is best-effort.
    }
  }, 120);
}

// ── Surface primitives ──

/**
 * Create a new pane for a subagent: a right split off the parent pi's pane,
 * so new panes follow the agent rather than the user's focus.
 * See https://github.com/HazAT/pi-interactive-subagents/issues/12
 *
 * Returns the new pane id (e.g. `%12`).
 */
export function createSurface(name: string): string {
  // The pi process inside shows its own title.
  if (isHerdrContext()) {
    requireTmux();
    return createHerdrTab(name);
  }
  if (detachedActive()) {
    // No parent pane exists to split; give the subagent its own session in
    // the private server so its pane survives independently and stays
    // attachable. Generous fixed geometry: nobody is looking until attached.
    requireTmux();
    ensureDetachedServer();
    const pane = execFileSync(
      "tmux",
      detachedArgs([
        "new-session",
        "-d",
        "-P",
        "-F",
        "#{pane_id}",
        "-n",
        name.replace(/\s+/g, "-").slice(0, 40) || "subagent",
        "-x",
        "200",
        "-y",
        "50",
      ]),
      { encoding: "utf8" },
    ).trim();
    if (!pane.startsWith("%")) {
      throw new Error(`Unexpected tmux new-session output: ${pane}`);
    }
    return pane;
  }
  return createSurfaceSplit(name, "right", process.env.TMUX_PANE);
}

/**
 * Create a new split in the given direction from an optional source pane.
 * Returns the new pane id (e.g. `%12`).
 */
export function createSurfaceSplit(
  name: string,
  direction: "left" | "right" | "up" | "down",
  fromSurface?: string,
): string {
  void name;
  requireTmux();
  if (isHerdrContext()) {
    if (direction === "left" || direction === "up") {
      throw new Error("Herdr supports right and down splits only.");
    }
    return createHerdrSurface(direction, fromSurface);
  }

  const args = ["split-window", "-d"];
  if (direction === "left" || direction === "right") {
    args.push("-h");
  } else {
    args.push("-v");
  }
  if (direction === "left" || direction === "up") {
    args.push("-b");
  }
  if (fromSurface) {
    args.push("-t", fromSurface);
  }
  args.push("-P", "-F", "#{pane_id}");

  const pane = execFileSync("tmux", detachedArgs(args), { encoding: "utf8" }).trim();
  if (!pane.startsWith("%")) {
    throw new Error(`Unexpected tmux split-window output: ${pane}`);
  }

  rebalanceSurfaces(pane);
  return pane;
}

/**
 * Send a command string to a pane and execute it.
 * Typed literally (`-l`) so special characters are not interpreted as keys,
 * then submitted with Enter.
 */
export function sendCommand(surface: string, command: string): void {
  requireTmux();
  if (isHerdrContext()) {
    sendHerdrCommand(surface, command);
    return;
  }
  execFileSync("tmux", detachedArgs(["send-keys", "-t", surface, "-l", command]), {
    encoding: "utf8",
  });
  execFileSync("tmux", detachedArgs(["send-keys", "-t", surface, "Enter"]), {
    encoding: "utf8",
  });
}

/**
 * Send a long command to a pane by writing it to a script file first.
 * This avoids terminal line-wrapping issues that break commands exceeding the
 * pane's column width when sent character-by-character via sendCommand.
 *
 * By default the script is written to a temp directory, but callers can pass a
 * stable path (for example under session artifacts) so the exact invocation is
 * preserved for debugging.
 *
 * Returns the script path.
 */
export function sendLongCommand(
  surface: string,
  command: string,
  options?: { scriptPath?: string; scriptPreamble?: string },
): string {
  const scriptPath =
    options?.scriptPath ??
    join(
      tmpdir(),
      "pi-subagent-scripts",
      `cmd-${Date.now()}-${Math.random().toString(16).slice(2, 8)}.sh`,
    );
  mkdirSync(dirname(scriptPath), { recursive: true });

  const scriptParts = ["#!/bin/bash"];
  if (options?.scriptPreamble) {
    scriptParts.push(options.scriptPreamble.trimEnd());
  }
  scriptParts.push(command);

  writeFileSync(scriptPath, scriptParts.join("\n") + "\n", {
    mode: 0o755,
  });
  sendCommand(surface, `bash ${shellEscape(scriptPath)}`);
  return scriptPath;
}

/**
 * Read the screen contents of a pane (sync).
 */
export function readScreen(surface: string, lines = 50): string {
  requireTmux();
  if (isHerdrContext()) return readHerdrScreen(surface, lines);
  return execFileSync(
    "tmux",
    detachedArgs(["capture-pane", "-p", "-t", surface, "-S", `-${Math.max(1, lines)}`]),
    {
      encoding: "utf8",
    },
  );
}

/**
 * Read the screen contents of a pane (async).
 */
export async function readScreenAsync(surface: string, lines = 50): Promise<string> {
  requireTmux();
  if (isHerdrContext()) return readHerdrScreenAsync(surface, lines);
  const { stdout } = await execFileAsync(
    "tmux",
    detachedArgs(["capture-pane", "-p", "-t", surface, "-S", `-${Math.max(1, lines)}`]),
    { encoding: "utf8" },
  );
  return stdout;
}

/**
 * Close a pane.
 */
export function closeSurface(surface: string): void {
  requireTmux();
  if (isHerdrContext()) {
    closeHerdrSurface(surface);
    return;
  }
  execFileSync("tmux", detachedArgs(["kill-pane", "-t", surface]), { encoding: "utf8" });
  rebalanceSurfaces();
}

/** Establish absence separately from a failed screen capture.
 * A backend failure rejects: it is not evidence that this pane disappeared.
 */
export async function surfaceExists(surface: string): Promise<boolean> {
  requireTmux();
  if (isHerdrContext()) return herdrSurfaceExists(surface);
  const { stdout } = await execFileAsync(
    "tmux",
    detachedArgs(["list-panes", "-a", "-F", "#{pane_id}"]),
    { encoding: "utf8" },
  );
  return stdout.trim().split("\n").includes(surface);
}
