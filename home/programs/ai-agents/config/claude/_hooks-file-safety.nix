# Native file-tool discipline shared by Claude Code.
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

            # Two distinct native guards share this failure channel; route each to
            # different guidance so the agent takes the right corrective action.
            if echo "$ERROR" | grep -Eqi 'file has not been read yet|read it first before writing|write_file_not_read'; then
              jq -n \
                --arg path "$FILE_PATH" \
                '{hookSpecificOutput: {hookEventName: "PostToolUseFailure", additionalContext: ("The native read-before-write guard rejected " + $path + ": no valid native Read exists for that path in the current user turn. Call native Read on that exact path now, then immediately retry Edit or Write. Reads from earlier turns, session history, CodeGraph, MCP, grep, or shell do not count — only a same-turn native Read does.")}}'
            elif echo "$ERROR" | grep -Eqi 'file has been modified since read|read it again before attempting to write|stale'; then
              jq -n \
                --arg path "$FILE_PATH" \
                '{hookSpecificOutput: {hookEventName: "PostToolUseFailure", additionalContext: ("The native stale-content guard rejected " + $path + ": the file changed on disk AFTER your last native Read. A formatter, linter, hook, or the user likely rewrote it. Call native Read on that exact path again now to load the new contents, reconcile your edit against the current text, then retry. Do NOT re-apply your old new_string verbatim — diff against what you just re-read or you will clobber the external change.")}}'
            else
              echo "$INPUT"
            fi
          '';
        }
      ];
    }
  ];
}
