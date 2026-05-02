# Import hub for split model/provider configuration files.

{
  imports = [
    ./codex.nix # Codex CLI configuration
    ./forge.nix # Forge (tailcallhq/forgecode) configuration
    ./gemini.nix # Gemini CLI configuration
    ./opencode.nix # OpenCode configuration
    ./omp.nix # Oh My Pi (can1357/oh-my-pi) configuration
    ./pi.nix # Pi (badlogic/pi-mono) configuration
  ];
}
