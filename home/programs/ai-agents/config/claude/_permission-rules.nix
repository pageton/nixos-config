# Allow and deny command/file patterns for Claude Code permissions.

let
  destructiveRules = import ../../helpers/_destructive-rules.nix;
in
{
  # Modern location for the default permission mode (top-level `defaultMode`
  # is not part of the Claude Code settings schema and is silently ignored).
  defaultMode = "bypassPermissions";

  allow = [
    "Bash(git *)"
    "Bash(gh *)"
    "Bash(npm run *)"
    "Bash(npx *)"
    "Bash(bunx *)"
    "Bash(pnpm *)"
    "Bash(bun *)"
    "Bash(uvx *)"
    "Bash(just *)"
    "Bash(make *)"
    "Bash(cmake *)"
    "Bash(nix *)"
    "Bash(nh *)"
    "Bash(home-manager *)"
    "Bash(cargo *)"
    "Bash(rustfmt *)"
    "Bash(go *)"
    "Bash(gofmt *)"
    "Bash(zig *)"
    "Bash(python *)"
    "Bash(pip *)"
    "Bash(uv *)"
    "Bash(ruff *)"
    "Bash(biome *)"
    "Bash(prettier *)"
    "Bash(statix *)"
    "Bash(deadnix *)"
    "Bash(docker *)"
    "Bash(docker-compose *)"
    "Bash(systemctl --user *)"
    "Bash(tmux *)"
    "mcp__codegraph__codegraph_search"
    "mcp__codegraph__codegraph_context"
    "mcp__codegraph__codegraph_callers"
    "mcp__codegraph__codegraph_callees"
    "mcp__codegraph__codegraph_impact"
    "mcp__codegraph__codegraph_explore"
    "mcp__codegraph__codegraph_trace"
    "mcp__codegraph__codegraph_node"
    "mcp__codegraph__codegraph_files"
    "mcp__codegraph__codegraph_status"
  ];

  deny =
    destructiveRules.mkClaudeDenyRules destructiveRules.systemCommands
    ++ destructiveRules.mkClaudeDenyRules destructiveRules.gitCommands
    ++ [
      # File read restrictions (not shell commands — Claude-specific).
      # In user settings `/path` anchors at ~/.claude, so home-directory
      # patterns need `~/` or the `//` absolute prefix.
      "Read(.env)"
      "Read(.env.*)"
      "Read(./secrets/**)"
      "Read(~/.ssh/**)"
      "Read(//**/id_rsa*)"
      "Read(//**/id_ed25519*)"
    ];
}
