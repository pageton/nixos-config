# Install everyday CLI tools and import terminal and shell configuration.

{ pkgs, ... }:

{
  imports = [
    ./alacritty.nix # Alacritty — default terminal
    ./ghostty.nix # Ghostty terminal emulator
    ./shell.nix # Shared shell, prompt, and tmux configuration
  ];

  # Everyday CLI tools without shell-managed packages.
  # Only tools not already provided elsewhere: most of yzua's original list
  # (fd, ripgrep, jq, fx, ffmpeg, …) is kept in home/packages (pkgsStable);
  # duplicating them here from `pkgs` would collide in the home profile.
  # Also provided elsewhere: nodejs_22 (languages/javascript),
  # openssl/openssl.dev (home/packages/networking), pnpm (languages/javascript).
  home.packages = [
    pkgs.bat
    pkgs.btop
    pkgs.eza
    pkgs.gh
    pkgs.git
    pkgs.lazygit
    pkgs.yt-dlp
  ];

  # Opt out of gh usage telemetry; extensions have separate settings.
  home.sessionVariables.GH_TELEMETRY = "false";
}
