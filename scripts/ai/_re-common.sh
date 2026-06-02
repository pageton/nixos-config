#!/usr/bin/env bash
# Shared RE infrastructure: workspace resolution and common helpers.
# Used by both android-re and web-re domains.
# Source this file after sourcing logging.sh and require.sh.

# Create a herdr space and run a command in its root pane.
# Usage: open_herdr_space <label> <command...>
# Returns 0 on success, 1 if herdr is unavailable or creation fails.
open_herdr_space() {
	local label="$1"
	shift
	if ! command -v herdr >/dev/null 2>&1; then
		return 1
	fi
	local ws_json pane_id
	ws_json="$(herdr workspace create --label "${label}" 2>/dev/null)" || {
		log_warning "failed to create herdr space for ${label}"
		return 1
	}
	pane_id="$(printf '%s' "${ws_json}" | python3 -c 'import sys,json; print(json.load(sys.stdin)["result"]["root_pane"]["pane_id"])' 2>/dev/null)" || {
		log_warning "failed to parse herdr pane id for ${label}"
		return 1
	}
	herdr pane run "${pane_id}" "$*" >/dev/null 2>&1 || {
		log_warning "failed to run command in herdr pane ${pane_id}"
		return 1
	}
	return 0
}

# Resolve the niri workspace reference containing a pattern in its name.
# Prints the workspace ref (or fallback if niri is unavailable/no match).
resolve_niri_workspace() {
	local pattern="$1"
	local fallback="${2:-}"
	if ! command -v niri >/dev/null 2>&1; then
		printf '%s\n' "${fallback}"
		return 0
	fi
	local ref
	ref="$(niri msg workspaces 2>/dev/null | sed -n "s/.*\"\([^\"]*${pattern}[^\"]*\)\".*/\1/p" | head -n1)"
	if [[ -n "${ref}" ]]; then
		printf '%s\n' "${ref}"
	else
		printf '%s\n' "${fallback}"
	fi
}
