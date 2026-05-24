# Security hooks — secret leak prevention for Write/Edit.

{ mkCommandHook }:

{
  PreToolUse = [
    (mkCommandHook {
      matcher = "Write|Edit";
      extractCommand = false;
      body = ''
        INPUT=$(cat)
        TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')

        # For Write: check new_string or full content
        # For Edit: check new_string only
        CONTENT=$(echo "$TOOL_INPUT" | jq -r 'if .content then .content elif .new_string then .new_string else "" end')
        FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')

        if [ -n "$CONTENT" ]; then
          SECRETS_FOUND=""

          # API keys and tokens
          if echo "$CONTENT" | grep -qE '(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|github_pat_[a-zA-Z0-9_]{22,}|glpat-[a-zA-Z0-9\-]{20,}|xox[bpas]-[a-zA-Z0-9\-]{10,}|hooks\.slack\.com/services/T[a-zA-Z0-9]{8,}/B[a-zA-Z0-9]{8,}/[a-zA-Z0-9]{24,})'; then
            SECRETS_FOUND="api-key"
          fi

          # Private keys
          if echo "$CONTENT" | grep -qE '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY'; then
            SECRETS_FOUND="''${SECRETS_FOUND:+$SECRETS_FOUND,}private-key"
          fi

          # AWS keys
          if echo "$CONTENT" | grep -qE '(AKIA[0-9A-Z]{16}|aws_secret_access_key)'; then
            SECRETS_FOUND="''${SECRETS_FOUND:+$SECRETS_FOUND,}aws-key"
          fi

          # Generic high-entropy tokens in assignment context
          if echo "$CONTENT" | grep -qE '(password|secret|token|api_key|apikey|access_key)\s*[:=]\s*["'\'''']?[A-Za-z0-9_\-]{20,}'; then
            SECRETS_FOUND="''${SECRETS_FOUND:+$SECRETS_FOUND,}hardcoded-secret"
          fi

          if [ -n "$SECRETS_FOUND" ]; then
            echo "[Hook] BLOCKED: potential secrets detected ($SECRETS_FOUND) in $FILE_PATH" >&2
            echo "[Hook] Use environment variables or a secrets manager instead." >&2
            exit 2
          fi
        fi

        echo "$INPUT"
      '';
    })
  ];
}
