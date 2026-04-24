# Home-Manager programs — application and tool configurations.
{ ... }:
{
  imports = [
    ./ai-agents # AI coding agent wrappers, launchers, and log analysis
    ./languages # Language toolchains (Go, Python, Node.js, etc.)
    ./terminal # Terminal, shell, and CLI tools
    ./nvf # Neovim via NVF framework
    ./zen-browser # Zen Browser with multi-profile proxy setup
    ./isolation # Application isolation wrappers
    ./gpg.nix # GPG key management and agent
    ./obs.nix # OBS Studio configuration
    ./brave.nix # Brave browser profile with proxy
    ./tailscale.nix # Tailscale VPN packages
    ./ssh.nix # SSH client configuration
    ./discord.nix # Discord/Vesktop theming via nixcord
    ./spicetify.nix # Spotify customization via spicetify-nix
    ./thunar.nix # Thunar file manager custom actions
    ./t3code.nix # T3 Code AI editor
    ./activitywatch.nix # ActivityWatch time tracking
  ];
}
