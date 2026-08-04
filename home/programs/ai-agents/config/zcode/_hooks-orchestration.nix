# ZCode orchestration approval handoff. Exact approval phrases are emitted by the
# orchestrator and validated again by its single-use token store before mutation.
{
  UserPromptSubmit = [
    {
      hooks = [
        {
          type = "command";
          enabled = true;
          timeoutMs = 5000;
          command = ''
            INPUT=$(cat)
            PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // ""')

            case "$PROMPT" in
              "APPROVE RUN "*|"APPROVE GIT "*|"APPROVE ROLLBACK "*)
                CONTEXT="The exact orchestration approval phrase was submitted. Continue only the matching pending zcode-orchestrator MCP operation, using the run id and single-use token already returned in this conversation. Do not execute repository mutations through Bash or any other tool."
                jq -n --arg context "$CONTEXT" '{
                  hookSpecificOutput: {
                    hookEventName: "UserPromptSubmit",
                    additionalContext: $context
                  }
                }'
                ;;
            esac
          '';
        }
      ];
    }
  ];
}
