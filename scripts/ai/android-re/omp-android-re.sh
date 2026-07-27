#!/usr/bin/env bash
# Launch an omp (Oh My Pi) Android RE session with emulator baseline.
# Called by om*are wrappers (ompre, ompglmare, ompdeepare, etc.)
# Env vars set by the Nix wrapper:
#   ANDROID_RE_OMP_PROFILE   - model profile name (default, glm, deepseek)
#
# The android-re prompt bundle (AGENTS.md, WORKFLOW.md, TOOLS.md, etc.)
# is injected via --append-system-prompt pointing at the prompt source dir.
#
# If no emulator is running, `re-avd.sh start-basic` is launched in the background so
# the agent session opens immediately instead of blocking on the full boot chain.
# start-basic boots only the emulator; the agent enables Frida/mitm/spoof on demand
# via `re-avd.sh frida-start`, `spoof`, `proxy-set`, etc.
# The agent can monitor progress with `re-avd.sh status` or `adb wait-for-device`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PROFILE="${ANDROID_RE_OMP_PROFILE:-default}"
START_LOG="${START_LOG:-${HOME}/Downloads/android-re-tools/re-avd-start.log}"

# Resolve model flag for the chosen profile
case "${PROFILE}" in
	glm)
		MODEL_FLAGS="--model zai-coding-plan/glm-5.2"
		;;
	deepseek)
		MODEL_FLAGS="--model deepseek/deepseek-v4-pro"
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
# Run start-basic in background so the omp session opens immediately;
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

# omp reads config from PI_CODING_AGENT_DIR (default: ~/.omp/agent).
# Build a runtime overlay that copies the base omp agent config,
# merges android-re MCP servers, and points omp at it.
BASE_OMP_AGENT_DIR="${HOME}/.omp/agent"
RUNTIME_CONFIG_PARENT="${XDG_CACHE_HOME:-${HOME}/.cache}/omp-android-re"
mkdir -p "${RUNTIME_CONFIG_PARENT}"
RUNTIME_AGENT_DIR="$(mktemp -d "${RUNTIME_CONFIG_PARENT}/${PROFILE}.XXXXXX")"

if [[ -d "${BASE_OMP_AGENT_DIR}" ]]; then
	# Copy base omp agent config (config.yml, models.db, history.db, extensions, skills).
	# Exclude sessions/ and run/ to keep the runtime dir light.
	rsync -a --exclude='sessions/' --exclude='run/' --exclude='wt/' \
		"${BASE_OMP_AGENT_DIR}/." "${RUNTIME_AGENT_DIR}/"
fi

# If mcp.json exists, merge the android-re MCP servers into it.
ANDROID_RE_MCP_FILE="${HOME}/.omp/agent/android-re-mcp-servers.json"
if [[ -f "${RUNTIME_AGENT_DIR}/mcp.json" ]] && [[ -f "${ANDROID_RE_MCP_FILE}" ]] && command -v jq >/dev/null 2>&1; then
	jq --slurpfile armcp "${ANDROID_RE_MCP_FILE}" \
		'.mcpServers += $armcp[0]' \
		"${RUNTIME_AGENT_DIR}/mcp.json" >"${RUNTIME_AGENT_DIR}/mcp.json.tmp"
	mv -f "${RUNTIME_AGENT_DIR}/mcp.json.tmp" "${RUNTIME_AGENT_DIR}/mcp.json"
fi

# Build the combined android-re prompt file from the prompt bundle.
# These are the same prompt files injected into the OpenCode/MiMoCode android-re agent.
PROMPT_SOURCE_DIR="${REPO_ROOT}/home/programs/ai-agents/android-re/prompts"
COMBINED_PROMPT_FILE="${RUNTIME_AGENT_DIR}/android-re-prompt.md"
if [[ -d "${PROMPT_SOURCE_DIR}" ]]; then
	{
		echo "# Android RE Agent System Prompt (omp)"
		echo ""
		echo "You are the dedicated Android reverse-engineering operator for this machine."
		echo "Use the repository's Android RE workspace as your system prompt and source of truth."
		echo ""
		echo "## Non-negotiable state contract"
		echo "- Every proof loop is: hypothesis -> smallest proof step -> exact evidence -> durable write -> next pivot."
		echo "- A result is not complete until write debt is zero."
		echo "- Do not start a new branch, spawn a subagent, or run a broad scan while prior evidence is only in chat context."
		echo ""
		echo "## Bash scripts (all run from repo root ${REPO_ROOT})"
		echo "scripts/ai/android-re/re-avd.sh          — emulator, root, Frida, proxy, cert, spoofing"
		echo "scripts/ai/android-re/re-static.sh       — static APK analysis (includes diff for version comparison)"
		echo "scripts/ai/android-re/workspace-init.sh  — target workspace initialization (~/Documents/{app-name}/)"
		echo "scripts/ai/android-re/findings.sh        — SQLite findings database CLI (init, add, list, update, query)"
		echo "scripts/ai/android-re/re-doctor.sh       — comprehensive tool audit for all TOOLS.md tools"
		echo "scripts/ai/android-re/_helpers.sh        — shared logging helpers"
		echo "scripts/ai/android-re/_spoof-table.sh    — declarative spoofing data (Pixel 7 profile)"
		echo ""
		echo "## Operating defaults"
		echo "- Prefer static triage before dynamic instrumentation."
		echo "- Use the rooted re-pixel7-api34 AVD as the baseline target unless evidence requires otherwise."
		echo "- Use 'su 0 ...' syntax for rooted ADB shell commands on this emulator."
		echo "- Prefer the system Frida 17.5.1 toolchain for attach and hook work."
		echo "- Device identity is spoofed automatically to look like a real Pixel 7 via re-avd.sh start."
		echo "- Prefer explicit proxy configuration plus QUIC blocking when using mitmproxy."
		echo "- Treat proxy failures as a triage problem: root/cert/proxy first, then pinning, Cronet, native TLS, or QUIC fallback."
		echo "- Use the repo workflow scripts under scripts/ai/android-re/ instead of ad-hoc command piles."
		echo "- Keep findings evidence-based and separate verified facts from inference."
		echo "- Maintain a target workspace at ~/Documents/{app-name}/ for session persistence across RE engagements."
		echo "- Write incrementally to prevent data loss from context compaction."
		echo "- You have Bash, Python 3.13, Node.js 24, and Bun 1.3. Write exploit scripts, fuzzing harnesses, replay tools freely."
		echo ""
		echo "## Full prompt bundle"
		echo ""
		for f in "${PROMPT_SOURCE_DIR}"/*.md; do
			echo "## $(basename "$f")"
			echo ""
			cat "$f"
			echo ""
			echo "---"
			echo ""
		done
	} >"${COMBINED_PROMPT_FILE}"
fi

# Launch omp via herdr space if available, otherwise alacritty, otherwise direct.
OMP_ARGS="--profile android-re ${MODEL_FLAGS}"
if [[ -f "${COMBINED_PROMPT_FILE}" ]]; then
	OMP_ARGS="${OMP_ARGS} --append-system-prompt ${COMBINED_PROMPT_FILE}"
fi

if open_herdr_space "android-re${PROFILE:+ (${PROFILE})}" "PI_CODING_AGENT_DIR=${RUNTIME_AGENT_DIR} exec omp ${OMP_ARGS} $*"; then
	exit 0
fi

if command -v alacritty >/dev/null 2>&1; then
	title="android-re"
	if [[ "${PROFILE}" != "default" ]]; then
		title="android-re (${PROFILE})"
	fi

	PI_CODING_AGENT_DIR="${RUNTIME_AGENT_DIR}" \
		exec alacritty --title "${title}" -e omp ${OMP_ARGS} "$@"
else
	# Fallback: run directly in current terminal
	PI_CODING_AGENT_DIR="${RUNTIME_AGENT_DIR}" \
		exec omp ${OMP_ARGS} "$@"
fi
