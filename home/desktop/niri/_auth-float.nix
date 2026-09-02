_: {
  home.file.".local/bin/niri-auth-float" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # niri-auth-float — automatically float popup windows that change title
      # after creation: browser auth/OAuth popups, Telegram Mini Apps, and
      # Telegram separate chat windows (title settles post-map).
      # Static window-rules can't catch title changes; this script does.

      set -euo pipefail

      # Browser auth patterns
      AUTH_PATTERN='(sign.?in|log.?in|تسجيل الدخول|connexion|anmelden|autenticación|authenticate|oauth|authorize|bitwarden.*vault|accounts\.google|login\.microsoft|github\.com/(login|oauth|sessions))'

      # Telegram separate chat windows: "<chat> @ <account> (<id>)" — kept in a
      # variable because [[ =~ ]] chokes on inline escaped spaces.
      TG_CHAT_TITLE_RE=' @ .*\([0-9]+\)$'


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
          niri msg action center-window --id "$win_id" 2>/dev/null || true
          floated[$win_id]=1
          return 0
        fi

        # Telegram separate chat windows ("<chat> @ <account> (<id>)") — the
        # title settles AFTER the window maps, so the static window-rule
        # (home/desktop/niri/rules.nix) can't catch them at open time.
        # Official-build Qt windows append "._<workdir-hash>" to the app-id,
        # so prefix-match; the plain form stays covered too.
        if [[ "$app_id" == "org.telegram.desktop"* ]] && [[ "$title" =~ $TG_CHAT_TITLE_RE ]]; then
          niri msg action toggle-window-floating --id "$win_id" 2>/dev/null || true
          niri msg action center-window --id "$win_id" 2>/dev/null || true
          floated[$win_id]=1
          return 0
        fi

        # Browser auth popups — only process browser app_ids
        case "$app_id" in
          *brave*|*firefox*|*librewolf*|*chromium*|*chrome*) ;;
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
