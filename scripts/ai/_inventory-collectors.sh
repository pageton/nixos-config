#!/usr/bin/env bash
# _inventory-collectors.sh - Per-tool data collection functions for agent inventory.
# Source this file after sourcing _inventory-helpers.sh and _inventory-walkers.sh.
#
# Generic directory-walking helpers (list_skill_dirs, list_skill_dirs_merged, etc.)
# live in _inventory-walkers.sh.  This file contains only the per-tool collectors
# that combine those walkers with tool-specific config parsing and row emission.

# Collect OpenCode inventory rows.
collect_opencode() {
	need_cmd jq
	shopt -s nullglob
	local profiles=("$HOME"/.config/opencode*/opencode.json)
	local agent_dirs=("$HOME"/.config/opencode*/agents)
	local skill_dirs=("$HOME"/.config/opencode*/skills)
	shopt -u nullglob

	local cfg profile_dir profile_name model small_model
	for cfg in "${profiles[@]}"; do
		profile_dir="$(dirname "$cfg")"
		profile_name="$(basename "$profile_dir")"

		model="$(jq -r '.model // "n/a"' "$cfg" 2>/dev/null || echo "n/a")"
		small_model="$(jq -r '.small_model // "n/a"' "$cfg" 2>/dev/null || echo "n/a")"

		row "opencode" "profile" "$profile_name" "model=$model" "$cfg"
		row "opencode" "small_model" "$profile_name" "$small_model" "$cfg"

		# shellcheck disable=SC2016
		collect_json_rows_jq "opencode" "command" "$cfg" '.command // {} | keys[]' '.command[$k].description // "no description"'
		collect_json_rows "opencode" "plugin" "$cfg" '.plugin // [] | .[]' "enabled"
		# shellcheck disable=SC2016
		collect_json_rows_jq "opencode" "mcp" "$cfg" '.mcp // {} | keys[]' '.mcp[$k].type // "local"'
		collect_json_rows "opencode" "provider" "$cfg" '.provider // {} | keys[]' "configured"
	done

	list_agent_files_merged "opencode" "${agent_dirs[@]}"
	list_skill_dirs_merged "opencode" "${skill_dirs[@]}" "$HOME/.agents/skills" "$PWD/.agents/skills"
	list_skill_commands_merged "opencode" "${skill_dirs[@]}" "$HOME/.agents/skills" "$PWD/.agents/skills"
}

# Collect Claude inventory rows.
collect_claude() {
	need_cmd jq
	local cfg="$HOME/.claude/settings.json"
	if [[ -f "$cfg" ]]; then
		row "claude" "model" "default" "$(jq -r '.model // "n/a"' "$cfg" 2>/dev/null || echo "n/a")" "$cfg"

		mapfile -t claude_configured_hooks < <(json_keys "$cfg" '.hooks // {} | keys[]')
		list_hook_rows_with_unconfigured "claude" "$cfg" "https://code.claude.com/docs/en/hooks" "${claude_configured_hooks[@]}"

		collect_json_rows "claude" "plugin" "$cfg" '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "enabled"
	fi

	local mcp_cfg="$HOME/.mcp.json"
	if [[ -f "$mcp_cfg" ]]; then
		collect_mcp_rows "claude" "$mcp_cfg"
	fi

	local agents_dir="$HOME/.claude/agents"
	if [[ -d "$agents_dir" ]]; then
		shopt -s nullglob
		local a
		for a in "$agents_dir"/*.md; do
			[[ -f "$a" ]] || continue
			local name
			name="$(awk -F': ' '/^name:/ {print $2; exit}' "$a" 2>/dev/null || true)"
			if [[ -z "$name" ]]; then
				name="$(basename "$a" .md)"
			fi
			row "claude" "agent" "$name" "local agent definition" "$a"
		done
		shopt -u nullglob
	fi

	list_skill_dirs_merged "claude" "$HOME/.claude/skills" "$HOME/.agents/skills"
	list_command_files "$HOME/.claude/commands" "claude"
}

# Collect Codex inventory rows.
collect_codex() {
	need_cmd python3
	local cfg="$HOME/.codex/config.toml"
	local agents_dir="$HOME/.codex/agents"
	if [[ -f "$cfg" ]]; then
		python3 - "$cfg" <<'PY'
import pathlib
import sys
import tomllib

cfg = pathlib.Path(sys.argv[1])
data = tomllib.loads(cfg.read_text(encoding="utf-8"))

def emit(kind: str, name: str, detail: str):
    print(f"codex\t{kind}\t{name}\t{detail}\t{cfg}")

emit("model", "default", str(data.get("model", "n/a")))
emit("reasoning_effort", "default", str(data.get("model_reasoning_effort", "n/a")))

for profile in sorted((data.get("profiles") or {}).keys()):
    emit("profile", profile, "configured")

for server, value in sorted((data.get("mcp_servers") or {}).items()):
    if isinstance(value, dict):
        enabled = value.get("enabled", True)
        emit("mcp", server, f"enabled={enabled}")

for agent in sorted((data.get("agents") or {}).keys()):
    if agent == "max_threads":
        continue
    emit("agent", agent, "configured")
PY
	fi

	list_skill_dirs_merged "codex" "$HOME/.codex/skills" "$HOME/.codex/skills/.system" "$HOME/.agents/skills" "$PWD/.agents/skills"
	list_command_files "$HOME/.codex/commands" "codex"
	if [[ -d "$agents_dir" ]]; then
		python3 - "$agents_dir" <<'PY'
import pathlib
import sys
import tomllib

agents_dir = pathlib.Path(sys.argv[1])
for agent_file in sorted(agents_dir.glob("*.toml")):
    try:
        data = tomllib.loads(agent_file.read_text(encoding="utf-8"))
    except Exception:
        continue
    name = str(data.get("name", agent_file.stem))
    desc = str(data.get("description", "custom agent"))
    print(f"codex\tagent\t{name}\t{desc}\t{agent_file}")
PY
	fi
}

# Collect Gemini inventory rows.
collect_gemini() {
	need_cmd jq
	local cfg="$HOME/.gemini/settings.json"
	if [[ -f "$cfg" ]]; then
		# shellcheck disable=SC2016
		collect_json_rows_jq "gemini" "model_alias" "$cfg" '.modelConfigs.customAliases // {} | keys[]' '.modelConfigs.customAliases[$k].modelConfig.model // "n/a"'

		mapfile -t gemini_configured_hooks < <(json_keys "$cfg" '.hooks // {} | keys[]')
		list_hook_rows_with_unconfigured "gemini" "$cfg" "https://geminicli.com/docs/hooks/reference/" "${gemini_configured_hooks[@]}"

		collect_mcp_rows "gemini" "$cfg"
	fi

	list_skill_dirs "$HOME/.gemini/skills" "gemini"
	list_command_files "$HOME/.gemini/commands" "gemini"
}

# Collect Pi inventory rows.
collect_pi() {
	need_cmd jq
	shopt -s nullglob
	local profiles=("$HOME"/.pi/profiles/*/settings.json)
	shopt -u nullglob

	local cfg profile_dir profile_name provider model thinking
	for cfg in "${profiles[@]}"; do
		profile_dir="$(dirname "$cfg")"
		profile_name="$(basename "$profile_dir")"

		provider="$(jq -r '.defaultProvider // "n/a"' "$cfg" 2>/dev/null || echo "n/a")"
		model="$(jq -r '.defaultModel // "n/a"' "$cfg" 2>/dev/null || echo "n/a")"
		thinking="$(jq -r '.defaultThinkingLevel // "n/a"' "$cfg" 2>/dev/null || echo "n/a")"

		row "pi" "profile" "$profile_name" "provider=$provider model=$model" "$cfg"
		row "pi" "thinking" "$profile_name" "$thinking" "$cfg"

		# Collect extensions listed in profile settings
		local extensions_cfg
		extensions_cfg="$(dirname "$cfg")"
		if [[ -f "$cfg" ]]; then
			local ext
			while IFS= read -r ext; do
				[[ -n "$ext" ]] || continue
				row "pi" "extension" "$profile_name" "$(basename "$ext")" "$ext"
			done < <(jq -r '.extensions[]? // empty' "$cfg" 2>/dev/null)
		fi

		# Collect custom providers from models.json
		local models_json="$profile_dir/models.json"
		if [[ -f "$models_json" ]]; then
			local prov_name
			while IFS= read -r prov_name; do
				[[ -n "$prov_name" ]] || continue
				local api
				api="$(jq -r ".providers.${prov_name}.api // \"n/a\"" "$models_json" 2>/dev/null || echo "n/a")"
				row "pi" "custom_provider" "$profile_name" "$prov_name ($api)" "$models_json"
			done < <(jq -r '.providers // {} | keys[]' "$models_json" 2>/dev/null)
		fi
	done

	# MCP manifest
	local mcp_manifest="$HOME/.pi/agent/mcp-manifest.json"
	if [[ -f "$mcp_manifest" ]]; then
		local srv_name
		while IFS= read -r srv_name; do
			[[ -n "$srv_name" ]] || continue
			local srv_type
			srv_type="$(jq -r ".servers[] | select(.name==\"$srv_name\") | .type // \"local\"" "$mcp_manifest" 2>/dev/null || echo "local")"
			row "pi" "mcp" "shared" "$srv_name ($srv_type)" "$mcp_manifest"
		done < <(jq -r '.servers[]?.name // empty' "$mcp_manifest" 2>/dev/null)
	fi

	# Shared extensions in ~/.pi/agent/extensions/
	shopt -s nullglob
	local exts=("$HOME"/.pi/agent/extensions/*.ts)
	shopt -u nullglob
	local ext
	for ext in "${exts[@]}"; do
		[[ -f "$ext" ]] || continue
		row "pi" "extension" "shared" "$(basename "$ext")" "$ext"
	done

	# Skills mirrored from Claude
	list_skill_dirs_merged "pi" "$HOME/.pi/agent/skills" "$HOME/.agents/skills"
}

# Dispatch to the correct collector(s) for a tool name.
collect_rows_for_tool() {
	local tool="$1"
	case "$tool" in
	opencode)
		collect_opencode
		;;
	claude)
		collect_claude
		;;
	codex)
		collect_codex
		;;
	gemini)
		collect_gemini
		;;
	pi)
		collect_pi
		;;
	all)
		collect_opencode
		collect_claude
		collect_codex
		collect_gemini
		collect_pi
		;;
	*)
		print_error "Unknown tool: $tool"
		exit 1
		;;
	esac
}
