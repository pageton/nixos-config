# Terminal, shell, and CLI tool modules.
{
  imports = [
    ./tools # CLI tools (bat, eza, git, atiu, btop, yazi, starship, etc.)
    ./zsh # Zsh shell configuration
    ./alacritty.nix # Alacritty terminal emulator
    ./ghostty.nix # Ghostty terminal emulator
    ./zellij # Zellij terminal multiplexer (plugins, layouts, keybinds)
    ./tmux.nix # Tmux terminal multiplexer (session persistence, vim navigation)
    ./direnv.nix # Per-directory environment loading
    ./scripts.nix # Custom utility scripts
    ./shell.nix # Nix shell integration and dev tools
  ];
}
