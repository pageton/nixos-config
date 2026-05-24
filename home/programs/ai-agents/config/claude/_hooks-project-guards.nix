# Project-specific guard hooks — large-file warnings, MTProto protection, Nix secrets blocking.

{ mkCommandHook }:

{
  PreToolUse = [
    # --- Large-file guard ---
    (mkCommandHook {
      matcher = "Write";
      extractCommand = false;
      body = ''
        INPUT=$(cat)
        FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
        CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // ""')
        LINE_COUNT=$(echo "$CONTENT" | wc -l)

        if [ "$LINE_COUNT" -gt 500 ]; then
          echo "[Hook] WARNING: Writing $FILE_PATH ($LINE_COUNT lines). Consider splitting into smaller files." >&2
        fi

        echo "$INPUT"
      '';
    })

    # --- MTProto / Telegram session protection ---
    (mkCommandHook {
      matcher = "Write|Edit";
      extractCommand = false;
      body = ''
        INPUT=$(cat)
        FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

        case "$FILE_PATH" in
          *.session)
            echo "[Hook] BLOCKED: .session files contain auth data — do not modify" >&2
            exit 2
            ;;
          */auth/key*|*/auth_key*|*/mtproto*)
            echo "[Hook] BLOCKED: MTProto auth/protocol files are protected" >&2
            exit 2
            ;;
        esac

        echo "$INPUT"
      '';
    })

    # --- NixOS secrets protection ---
    (mkCommandHook {
      matcher = "Write|Edit";
      extractCommand = false;
      body = ''
        INPUT=$(cat)
        FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

        case "$FILE_PATH" in
          */secrets/*|*hardware/secrets*|*/hardware-configuration.nix)
            echo "[Hook] WARNING: Editing sensitive file — $FILE_PATH. Ensure no secrets are exposed." >&2
            ;;
        esac

        echo "$INPUT"
      '';
    })
  ];

  PostToolUse = [
    # --- Post-write file size check for Edit ---
    (mkCommandHook {
      matcher = "Edit";
      extractCommand = false;
      body = ''
        INPUT=$(cat)
        FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

        if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
          LINE_COUNT=$(wc -l < "$FILE_PATH")
          if [ "$LINE_COUNT" -gt 500 ]; then
            echo "[Hook] WARNING: $FILE_PATH is now $LINE_COUNT lines. Consider splitting." >&2
          fi
        fi

        echo "$INPUT"
      '';
    })
  ];
}
