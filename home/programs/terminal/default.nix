# Terminal, shell, and CLI tool modules.
{ pkgs, ... }: {
  imports = [
    ./tools # CLI tools (bat, eza, atuin, btop, yazi, starship, etc.)
    ./zsh # Zsh shell configuration
    ./alacritty.nix # Alacritty terminal emulator
    ./zellij # Zellij terminal multiplexer (plugins, layouts, keybinds)
    ./tmux.nix # Tmux terminal multiplexer (session persistence, vim navigation)
    ./direnv.nix # Per-directory environment loading
    ./scripts.nix # Custom utility scripts
    ./shell.nix # Nix shell integration and dev tools
  ];

  # Git is installed here because home/programs/git.nix sets package = null
  # and the old tools/git module (which installed it) is superseded there.
  home.packages = [
    pkgs.git
    pkgs.yt-dlp
  ];

  # Opt out of gh usage telemetry; extensions have separate settings.
  home.sessionVariables.GH_TELEMETRY = "false";
}
