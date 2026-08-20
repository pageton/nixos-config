#!/usr/bin/env bash
# Launch a MiMoCode web RE session with Chrome baseline.
# Called by mi*wre wrappers.
# Env vars set by the Nix wrapper:
#   WEB_RE_MIMO_PROFILE   - mimo profile slug (default, glm, deepseek)
# The web-re agent's system prompt already contains the full RE prompt bundle
# (AGENTS.md, WORKFLOW.md, TOOLS.md, TROUBLESHOOTING.md, README.md) injected at Nix eval
# time into ~/.config/mimocode/config.json (agent.web-re). No need to pass via --prompt.
#
# If Chrome is not running with remote debugging, it is launched in the background so the
# agent session opens immediately instead of blocking.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PROFILE="${WEB_RE_MIMO_PROFILE:-default}"
START_LOG="${START_LOG:-${HOME}/Downloads/web-re-tools/web-re-start.log}"

# MiMoCode uses a single config dir (~/.config/mimocode); profiles select a model via -m.
BASE_MIMO_CONFIG_DIR="$HOME/.config/mimocode"
case "${PROFILE}" in
	glm)
		MODEL_FLAGS="-m zai-coding-plan/glm-5.3"
		;;
	deepseek)
		MODEL_FLAGS="-m deepseek/deepseek-v4-pro"
		;;
	*)
		MODEL_FLAGS=""
		;;
esac

# Focus the web-re workspace in niri -- window rule by title "^web-re" places it correctly
# shellcheck source=scripts/lib/logging.sh
source "${REPO_ROOT}/scripts/lib/logging.sh"
# shellcheck source=scripts/ai/web-re/_helpers.sh
source "${SCRIPT_DIR}/_helpers.sh"
# shellcheck source=scripts/ai/web-re/_tmux.sh
source "${SCRIPT_DIR}/_tmux.sh"
# shellcheck source=scripts/ai/web-re/_chrome.sh
source "${SCRIPT_DIR}/_chrome.sh"
# shellcheck source=scripts/ai/web-re/_mitm.sh
source "${SCRIPT_DIR}/_mitm.sh"
focus_re_workspace
sleep 0.3

# Create tmux session for mitm, proxy, logs, and recon panes
ensure_re_tmux

# Start mitmproxy in the mitm tmux pane (non-fatal)
if ! mitm_start; then
	echo "mitmproxy setup skipped — tmux session still available"
fi

# Start Chrome with remote debugging if nothing is running.
if ! chrome_running; then
	echo "Chrome not running with remote debugging -- starting web RE baseline in background (log: ${START_LOG})"
	mkdir -p "$(dirname "${START_LOG}")"
	chrome_start "$@"
else
	echo "Chrome already running -- checking status..."
	chrome_status
fi

# MiMoCode reads its config dir from MIMOCODE_CONFIG_DIR. Build a runtime overlay that copies
# the global mimo config, pins default_agent=web-re, and merges web-re MCP servers.
RUNTIME_CONFIG_PARENT="${XDG_CACHE_HOME:-${HOME}/.cache}/mimo-web-re"
mkdir -p "${RUNTIME_CONFIG_PARENT}"
RUNTIME_CONFIG_DIR="$(mktemp -d "${RUNTIME_CONFIG_PARENT}/${PROFILE}.XXXXXX")"

if [[ -d "${BASE_MIMO_CONFIG_DIR}" ]]; then
	# Preserve full mimo config (config.json, plugins, node_modules) in the runtime overlay.
	cp -a "${BASE_MIMO_CONFIG_DIR}/." "${RUNTIME_CONFIG_DIR}/"
fi

if [[ -f "${RUNTIME_CONFIG_DIR}/config.json" ]] && command -v jq >/dev/null 2>&1; then
	jq '.default_agent = "web-re"' "${RUNTIME_CONFIG_DIR}/config.json" >"${RUNTIME_CONFIG_DIR}/config.json.tmp"
	mv -f "${RUNTIME_CONFIG_DIR}/config.json.tmp" "${RUNTIME_CONFIG_DIR}/config.json"

	# Merge web-re-specific MCP servers into runtime config.
	# These are NOT in the shared mimo config -- they only appear in the web-re overlay.
	WEB_RE_MCP_FILE="$HOME/.config/mimocode/web-re-mcp-servers.json"
	if [[ -f "${WEB_RE_MCP_FILE}" ]]; then
		jq --slurpfile wrmcp "${WEB_RE_MCP_FILE}" \
			'.mcp += $wrmcp[0]' \
			"${RUNTIME_CONFIG_DIR}/config.json" >"${RUNTIME_CONFIG_DIR}/config.json.tmp"
		mv -f "${RUNTIME_CONFIG_DIR}/config.json.tmp" "${RUNTIME_CONFIG_DIR}/config.json"
	fi
fi

# Spawn a herdr space for the tmux session (non-blocking).
open_re_terminal

# Open mimo in herdr space (preferred) or Alacritty fallback.
if open_herdr_space "web-re${PROFILE:+ (${PROFILE})}" "MIMOCODE_CONFIG_DIR=${RUNTIME_CONFIG_DIR} exec mimo ${MODEL_FLAGS} $*"; then
	exit 0
fi

if command -v alacritty >/dev/null 2>&1; then
	title="web-re"
	if [[ "${PROFILE}" != "default" ]]; then
		title="web-re (${PROFILE})"
	fi

	MIMOCODE_CONFIG_DIR="${RUNTIME_CONFIG_DIR}" \
		exec alacritty --title "${title}" -e mimo ${MODEL_FLAGS} "$@"
else
	# Fallback: run directly in current terminal
	MIMOCODE_CONFIG_DIR="${RUNTIME_CONFIG_DIR}" \
		exec mimo ${MODEL_FLAGS} "$@"
fi
