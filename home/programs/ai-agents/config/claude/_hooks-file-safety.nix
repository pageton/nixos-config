# Native file-tool discipline shared by Claude Code and ZCode.
let
  readGuidance = "Before Edit or Write modifies an existing file, call the native Read tool on that exact path in this session. CodeGraph, MCP, grep, and shell reads do not satisfy the native stale-file guard. If a formatter, hook, user, or other process changes the file after it was read, call Read again immediately before editing. Use Write without Read only to create a new file.";

  mkContextExecutor = eventName: {
    type = "command";
    command = ''
      cat >/dev/null
      jq -n '{hookSpecificOutput: {hookEventName: "${eventName}", additionalContext: ${builtins.toJSON readGuidance}}}'
    '';
  };
in
{
  SessionStart = [
    {
      matcher = "startup|resume|clear|compact|fork";
      hooks = [ (mkContextExecutor "SessionStart") ];
    }
  ];

  UserPromptSubmit = [ { hooks = [ (mkContextExecutor "UserPromptSubmit") ]; } ];

  PostToolUseFailure = [
    {
      matcher = "Edit|Write";
      hooks = [
        {
          type = "command";
          command = ''
            INPUT=$(cat)
            ERROR=$(echo "$INPUT" | jq -r '.error // .tool_response.error // .tool_response.message // ""')
            FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .file_path // "the target file"')

            if echo "$ERROR" | grep -Eqi 'file has not been read yet|read it first before writing|write_file_not_read|file has been modified since read|read it again before attempting to write'; then
              jq -n \
                --arg path "$FILE_PATH" \
                '{hookSpecificOutput: {hookEventName: "PostToolUseFailure", additionalContext: ("The native stale-file guard rejected " + $path + " because it was not read with the native Read tool or changed after its last native Read. Call Read on that exact path now, then immediately retry Edit or Write using the current content. CodeGraph, MCP, grep, and shell reads do not satisfy this guard.")}}'
            else
              echo "$INPUT"
            fi
          '';
        }
      ];
    }
  ];
}
