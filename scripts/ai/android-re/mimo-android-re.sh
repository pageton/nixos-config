#!/usr/bin/env bash
# Launch a MiMoCode Android RE session with emulator baseline.
# Called by mi*are wrappers (miare, miglmare, miskare, etc.)
# Env vars set by the Nix wrapper:
#   ANDROID_RE_MIMO_PROFILE   - mimo profile slug (default, glm, deepseek)
#
# The android-re agent's system prompt already contains the full RE prompt bundle
# (AGENTS.md, WORKFLOW.md, TOOLS.md, TROUBLESHOOTING.md, README.md) injected at Nix eval
# time into ~/.config/mimocode/config.json (agent.android-re). No need to pass via --prompt.
#
# If no emulator is running, `re-avd.sh start-basic` is launched in the background so
# the agent session opens immediately instead of blocking on the full boot chain.
# start-basic boots only the emulator; the agent enables Frida/mitm/spoof on demand
# via `re-avd.sh frida-start`, `spoof`, `proxy-set`, etc.
# The agent can monitor progress with `re-avd.sh status` or `adb wait-for-device`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PROFILE="${ANDROID_RE_MIMO_PROFILE:-default}"
START_LOG="${START_LOG:-${HOME}/Downloads/android-re-tools/re-avd-start.log}"

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

# Focus the android workspace in niri — window rule by title "^android-re" places it correctly
# shellcheck source=scripts/lib/logging.sh
source "${REPO_ROOT}/scripts/lib/logging.sh"
# shellcheck source=scripts/ai/android-re/_helpers.sh
source "${SCRIPT_DIR}/_helpers.sh"
NIRI_WS_REF="$(resolve_niri_android_workspace)"
if command -v niri >/dev/null 2>&1 && niri msg version >/dev/null 2>&1; then
	if [[ -n "${NIRI_WS_REF}" ]]; then
		niri msg action focus-workspace "${NIRI_WS_REF}" >/dev/null 2>&1 || true
		sleep 0.3
	fi
fi

# Boot the emulator baseline if nothing is running.
# Run start-basic in background so the MiMoCode session opens immediately;
# the agent can check readiness with `re-avd.sh status` or `adb wait-for-device`.
if ! emulator_online; then
	echo "No emulator running — starting emulator (start-basic) in background (log: ${START_LOG})"
	nohup bash "${SCRIPT_DIR}/re-avd.sh" start-basic >"${START_LOG}" 2>&1 &
	START_PID=$!
	echo "re-avd.sh start-basic PID: ${START_PID}"
	echo "Monitor with: tail -f ${START_LOG}"
else
	echo "Emulator already running — checking status..."
	bash "${SCRIPT_DIR}/re-avd.sh" status
fi

# MiMoCode reads its config dir from MIMOCODE_CONFIG_DIR. Build a runtime overlay that copies
# the global mimo config, pins default_agent=android-re, and merges android-re MCP servers.
RUNTIME_CONFIG_PARENT="${XDG_CACHE_HOME:-${HOME}/.cache}/mimo-android-re"
mkdir -p "${RUNTIME_CONFIG_PARENT}"
RUNTIME_CONFIG_DIR="$(mktemp -d "${RUNTIME_CONFIG_PARENT}/${PROFILE}.XXXXXX")"

if [[ -d "${BASE_MIMO_CONFIG_DIR}" ]]; then
	# Preserve full mimo config (config.json, plugins, node_modules) in the runtime overlay.
	cp -a "${BASE_MIMO_CONFIG_DIR}/." "${RUNTIME_CONFIG_DIR}/"
fi

if [[ -f "${RUNTIME_CONFIG_DIR}/config.json" ]] && command -v jq >/dev/null 2>&1; then
	jq '.default_agent = "android-re"' "${RUNTIME_CONFIG_DIR}/config.json" >"${RUNTIME_CONFIG_DIR}/config.json.tmp"
	mv -f "${RUNTIME_CONFIG_DIR}/config.json.tmp" "${RUNTIME_CONFIG_DIR}/config.json"

	# Merge android-re-specific MCP servers (Ghidra, JADX, apktool) into runtime config.
	# These are NOT in the shared mimo config — they only appear in the android-re overlay.
	ANDROID_RE_MCP_FILE="$HOME/.config/mimocode/android-re-mcp-servers.json"
	if [[ -f "${ANDROID_RE_MCP_FILE}" ]]; then
		jq --slurpfile armcp "${ANDROID_RE_MCP_FILE}" \
			'.mcp += $armcp[0]' \
			"${RUNTIME_CONFIG_DIR}/config.json" >"${RUNTIME_CONFIG_DIR}/config.json.tmp"
		mv -f "${RUNTIME_CONFIG_DIR}/config.json.tmp" "${RUNTIME_CONFIG_DIR}/config.json"
	fi
fi

if open_herdr_space "android-re${PROFILE:+ (${PROFILE})}" "MIMOCODE_CONFIG_DIR=${RUNTIME_CONFIG_DIR} exec mimo ${MODEL_FLAGS} $*"; then
	exit 0
fi

if command -v alacritty >/dev/null 2>&1; then
	title="android-re"
	if [[ "${PROFILE}" != "default" ]]; then
		title="android-re (${PROFILE})"
	fi

	MIMOCODE_CONFIG_DIR="${RUNTIME_CONFIG_DIR}" \
		exec alacritty --title "${title}" -e mimo ${MODEL_FLAGS} "$@"
else
	# Fallback: run directly in current terminal
	MIMOCODE_CONFIG_DIR="${RUNTIME_CONFIG_DIR}" \
		exec mimo ${MODEL_FLAGS} "$@"
fi
