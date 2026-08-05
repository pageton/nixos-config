# Native file-tool discipline shared by Claude Code and ZCode.
let
  readGuidance = "MANDATORY FILE-WRITE PRECONDITION: Before the first Edit or Write to each existing file in every user turn, call the native Read tool on that exact path during the same turn. A Read from an earlier turn or session history does not count; neither do CodeGraph, MCP, grep, or shell reads. If a formatter, hook, user, or other process changes the file after that native Read, call Read again before editing. Write may skip Read only when creating a path that does not exist.";

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
                '{hookSpecificOutput: {hookEventName: "PostToolUseFailure", additionalContext: ("The native stale-file guard rejected " + $path + " because the current user turn has no valid native Read for that path, or the file changed after its last native Read. Call native Read on that exact path now, then immediately retry Edit or Write. Reads from earlier turns or session history do not count; neither do CodeGraph, MCP, grep, or shell reads.")}}'
            else
              echo "$INPUT"
            fi
          '';
        }
      ];
    }
  ];
}
