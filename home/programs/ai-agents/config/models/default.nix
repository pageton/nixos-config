# Import hub for split model/provider configuration files.

{
  imports = [
    ./codex.nix # Codex CLI configuration
    ./forge.nix # Forge (tailcallhq/forgecode) configuration
    ./gemini.nix # Gemini CLI configuration
    ./opencode.nix # OpenCode configuration
    ./pi.nix # Pi coding agent configuration
  ];
}
