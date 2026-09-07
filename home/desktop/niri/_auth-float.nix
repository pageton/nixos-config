_: {
  home.file.".local/bin/niri-auth-float" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # niri-auth-float — automatically float popup windows whose title only
      # settles after creation: browser auth/OAuth popups. Stable app-id
      # floats (Telegram window classes, dialogs) live in rules.nix; this
      # script covers only what title-based static rules can't catch.

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

        # Browser auth popups — only process browser app_ids
        case "$app_id" in
          *brave*|*firefox*|*librewolf*|*chromium*|*chrome*) ;;
          *) return 0 ;;
        esac

        # Check title against auth patterns. These popups settle late, so
        # they're floated AFTER being tiled — the toggle keeps the tiled
        # geometry. Pin the old dialog float size (958x790, same as the
        # portal filechooser rule) and center, matching what the old
        # open-time static rule looked like.
        if echo "$title" | grep -qiE "$AUTH_PATTERN"; then
          niri msg action toggle-window-floating --id "$win_id" 2>/dev/null || true
          niri msg action set-window-width --id "$win_id" 958 2>/dev/null || true
          niri msg action set-window-height --id "$win_id" 790 2>/dev/null || true
          niri msg action center-window --id "$win_id" 2>/dev/null || true
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
