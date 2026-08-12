# Import hub for split AI agent configuration files.

{
  imports = [
    ./defaults.nix # Enablement, shared instructions, and skill defaults
    ./mcp-servers.nix # MCP server definitions and logging
    ./mcp-servers-android-re.nix # Android RE agent-specific MCP servers
    ./mcp-servers-web-re.nix # Web RE agent-specific MCP servers (not shared globally)
    ./models # Model/provider registries (OpenCode, Codex, OMP)
    ./claude # Claude Code permissions, hooks, and settings
    ./herdr.nix # herdr config via upstream home-manager module
  ];
}
