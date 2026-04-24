{ pkgs, ... }:
{
  home.file.".local/bin/niri-auth-float" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # niri-auth-float — automatically float popup windows that change title
      # after creation. Handles browser auth/OAuth popups and Telegram Mini Apps.
      # Static window-rules can't catch title changes; this script does.

      set -euo pipefail

      # Browser auth patterns
      AUTH_PATTERN='(sign.?in|log.?in|تسجيل الدخول|connexion|anmelden|autenticación|authenticate|oauth|authorize|bitwarden.*vault|accounts\.google|login\.microsoft|github\.com/(login|oauth|sessions))'

      declare -A floated=()

      handle_event() {
        local line="$1"

        # Only process window change events
        [[ "$line" != *"Window opened or changed:"* ]] && return 0

        # Extract window ID
        local win_id
        win_id=$(echo "$line" | grep -oP 'Window \{ id: \K[0-9]+') || return 0

        # Skip if already floated
        [[ -n "''${floated[$win_id]+x}" ]] && return 0

        # Skip if already floating
        [[ "$line" == *"is_floating: true"* ]] && return 0

        # Extract title (handle unicode in the text format)
        local title
        title=$(echo "$line" | grep -oP 'title: Some\("\K[^"]*') || return 0

        # Extract app_id
        local app_id
        app_id=$(echo "$line" | grep -oP 'app_id: Some\("\K[^"]*') || return 0

        # Telegram Mini Apps — match by title prefix
        if [[ "$title" == "Mini App: "* ]]; then
          niri msg action toggle-window-floating --id "$win_id" 2>/dev/null || true
          floated[$win_id]=1
          return 0
        fi

        # Browser auth popups — only process browser app_ids
        case "$app_id" in
          *brave*|*firefox*|*zen*|*chromium*|*chrome*) ;;
          *) return 0 ;;
        esac

        # Check title against auth patterns
        if echo "$title" | grep -qiE "$AUTH_PATTERN"; then
          niri msg action toggle-window-floating --id "$win_id" 2>/dev/null || true
          floated[$win_id]=1
        fi
      }

      # Process event-stream
      while IFS= read -r line; do
        handle_event "$line"
      done < <(exec niri msg event-stream 2>&1)
    '';
  };
}
