/**
 * Agent Switcher Extension for pi-coding-agent.
 *
 * Works like claude-code / opencode / forgecode / codex agent switching:
 *   /agent            → native picker UI
 *   /agent <name>     → switch directly
 *   /agent:<name>     → direct shortcut with optional task
 *
 * Uses the `before_agent_start` event to inject the agent persona as
 * system prompt — the LLM adopts the persona permanently for all
 * subsequent turns, matching the UX of other coding agents.
 *
 * Agents are loaded from `~/.pi/agent/agents/<name>/SKILL.md`.
 */
import { readdirSync, readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

interface AutocompleteItem {
  value: string;
  label: string;
  description?: string;
}

interface AgentDef {
  name: string;
  description: string;
  body: string;
}

function parseFrontmatter(content: string): { frontmatter: Record<string, string>; body: string } {
  const match = content.match(/^---\s*\n([\s\S]*?)\n---\s*\n([\s\S]*)$/);
  if (!match) return { frontmatter: {}, body: content.trim() };
  const frontmatter: Record<string, string> = {};
  for (const line of match[1].split("\n")) {
    const kv = line.match(/^(\w+):\s*(.+)$/);
    if (kv) frontmatter[kv[1]] = kv[2].trim();
  }
  return { frontmatter, body: match[2].trim() };
}

function loadAgents(): AgentDef[] {
  const agentsDir = join(homedir(), ".pi", "agent", "agents");
  if (!existsSync(agentsDir)) return [];
  const agents: AgentDef[] = [];
  for (const entry of readdirSync(agentsDir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const skillFile = join(agentsDir, entry.name, "SKILL.md");
    if (!existsSync(skillFile)) continue;
    try {
      const content = readFileSync(skillFile, "utf8");
      const { frontmatter, body } = parseFrontmatter(content);
      agents.push({
        name: frontmatter.name || entry.name,
        description: frontmatter.description || "No description",
        body,
      });
    } catch { /* skip */ }
  }
  return agents;
}

export default function (pi: ExtensionAPI): void {
  const agents = loadAgents();
  let activeAgent: AgentDef | null = null;

  const agentAutocomplete: AutocompleteItem[] = agents.map((a) => ({
    value: a.name,
    label: a.name,
    description: a.description,
  }));

  function resolveAgent(input: string): AgentDef | null {
    const t = input.trim();
    if (!t) return null;
    const num = parseInt(t, 10);
    if (!isNaN(num) && num >= 1 && num <= agents.length) return agents[num - 1];
    return agents.find((a) => a.name === t) ?? agents.find((a) => a.name.startsWith(t)) ?? null;
  }

  // --- Inject agent persona into system prompt on every turn ---
  // This matches how claude-code/opencode/forgecode work: the agent's
  // instructions become permanent steering context, not a one-shot message.
  pi.on("before_agent_start", (_event, _ctx) => {
    if (!activeAgent) return;
    return {
      systemPrompt: activeAgent.body,
    };
  });

  // --- /agent command ---
  pi.registerCommand("agent", {
    description: "Switch agent persona (like claude-code /agent)",
    getArgumentCompletions(prefix: string): AutocompleteItem[] | null {
      if (!prefix) return agentAutocomplete;
      const lower = prefix.toLowerCase();
      const filtered = agentAutocomplete.filter(
        (item) => item.value.toLowerCase().startsWith(lower),
      );
      return filtered.length > 0 ? filtered : null;
    },
    async handler(args, ctx) {
      const trimmed = (args ?? "").trim();

      // /agent list — show current
      if (trimmed === "list" || trimmed === "ls") {
        if (activeAgent) {
          ctx.ui.notify(`Active agent: ${activeAgent.name}`, "info");
        } else {
          ctx.ui.notify("No agent active (using default)", "info");
        }
        return;
      }

      // /agent off — deactivate
      if (trimmed === "off" || trimmed === "none") {
        activeAgent = null;
        ctx.ui.notify("Agent deactivated — using default", "info");
        return;
      }

      // /agent <name> — switch directly
      if (trimmed) {
        const agentName = trimmed.split(/\s+/)[0];
        const agent = resolveAgent(agentName);
        if (agent) {
          activeAgent = agent;
          ctx.ui.notify(`✓ ${agent.name}`, "info");
          return;
        }
      }

      // /agent (no args) — show picker
      if (ctx.hasUI && agents.length > 0) {
        const options = agents.map((a) => `${a.name}  —  ${a.description}`);
        const selected = await ctx.ui.select("Select agent persona", options);
        if (selected) {
          const idx = options.indexOf(selected);
          if (idx >= 0) {
            activeAgent = agents[idx];
            ctx.ui.notify(`✓ ${agents[idx].name}`, "info");
            return;
          }
        }
        return;
      }

      // Fallback
      if (agents.length === 0) {
        ctx.ui.notify("No agents found in ~/.pi/agent/agents/", "warning");
        return;
      }
      const lines = agents.map(
        (a, i) => `  ${String(i + 1).padStart(2)}. ${a.name.padEnd(28)} ${a.description}`,
      );
      ctx.ui.notify(
        ["Select agent:", ...lines, "", "Usage: /agent <name> | /agent off"].join("\n"),
        "info",
      );
    },
  });

  // --- /agent:<name> shortcuts ---
  for (const agent of agents) {
    const ag = agent;
    pi.registerCommand(`agent:${ag.name}`, {
      description: ag.description,
      async handler(_args, ctx) {
        activeAgent = ag;
        ctx.ui.notify(`✓ ${ag.name}`, "info");
      },
    });
  }
}
