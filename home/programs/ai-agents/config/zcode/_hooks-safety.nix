# ZCode file-modification discipline and recovery hooks.
{
  SessionStart = [
    {
      matcher = "startup|clear|compact";
      hooks = [
        {
          type = "command";
          enabled = true;
          timeoutMs = 5000;
          command = ''
            cat >/dev/null
            CONTEXT='ZCode requires its native Read tool before Edit or Write can modify an existing file. A CodeGraph, MCP, grep, or shell read does not satisfy this guard. Call Read on the exact path immediately before editing; if a formatter, hook, or other process changes the file afterward, call Read again. Write may be used without Read only to create a new file.'
            jq -n --arg context "$CONTEXT" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $context}}'
          '';
        }
      ];
    }
  ];

  PostToolUseFailure = [
    {
      matcher = "Write|Edit";
      hooks = [
        {
          type = "command";
          enabled = true;
          timeoutMs = 5000;
          command = ''
            INPUT=$(cat)
            ERROR=$(echo "$INPUT" | jq -r '.error // .tool_response.error // .tool_response.message // ""')
            FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .file_path // "the target file"')

            if echo "$ERROR" | grep -Eqi 'file has not been read yet|read it first before writing|write_file_not_read|file has been modified since read|read it again before attempting to write'; then
              jq -n \
                --arg path "$FILE_PATH" \
                '{hookSpecificOutput: {hookEventName: "PostToolUseFailure", additionalContext: ("The ZCode write guard rejected " + $path + " because it was not read with the native Read tool or changed after its last native Read. Call Read on that exact path now, then immediately retry Edit or Write using the current content. CodeGraph, MCP, grep, and shell reads do not satisfy this guard.")}}'
            else
              echo "$INPUT"
            fi
          '';
        }
      ];
    }
  ];
}
