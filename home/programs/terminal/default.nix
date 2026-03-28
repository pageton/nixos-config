# Terminal, shell, and CLI tool modules.
{
  imports = [
    ./tools # CLI tools (bat, eza, git, atuin, btop, yazi, starship, etc.)
    ./zsh # Zsh shell configuration
    ./alacritty.nix # Alacritty terminal emulator
    ./zellij # Zellij terminal multiplexer (plugins, layouts, keybinds)
    ./direnv.nix # Per-directory environment loading
    ./scripts.nix # Custom utility scripts
    ./shell.nix # Nix shell integration and dev tools
  ];
}
