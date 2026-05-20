# herdr agent state hooks for Claude Code.
# Reports working/blocked/idle/release to herdr's socket API.
{ }:

let
  herdrHookScript = "$HOME/.claude/hooks/herdr-agent-state.sh";
in
{
  UserPromptSubmit = [
    {
      hooks = [
        {
          type = "command";
          command = "${herdrHookScript} working";
        }
      ];
    }
  ];

  PreToolUse = [
    {
      hooks = [
        {
          type = "command";
          command = "${herdrHookScript} working";
        }
      ];
    }
  ];

  PermissionRequest = [
    {
      hooks = [
        {
          type = "command";
          command = "${herdrHookScript} blocked";
        }
      ];
    }
  ];

  PostToolUse = [
    {
      hooks = [
        {
          type = "command";
          command = "${herdrHookScript} working";
        }
      ];
    }
  ];

  PostToolUseFailure = [
    {
      hooks = [
        {
          type = "command";
          command = "${herdrHookScript} working";
        }
      ];
    }
  ];

  SubagentStop = [
    {
      hooks = [
        {
          type = "command";
          command = "${herdrHookScript} working";
        }
      ];
    }
  ];

  Stop = [
    {
      hooks = [
        {
          type = "command";
          command = "${herdrHookScript} idle";
        }
      ];
    }
  ];

  SessionEnd = [
    {
      hooks = [
        {
          type = "command";
          command = "${herdrHookScript} release";
        }
      ];
    }
  ];
}
