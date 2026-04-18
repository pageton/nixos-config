# Home-Manager programs — application and tool configurations.
{ ... }:
{
  imports = [
    ./ai-agents # AI coding agent wrappers, launchers, and log analysis
    ./languages # Language toolchains (Go, Python, Node.js, etc.)
    ./gpg # GPG key management and agent
    ./obs # OBS Studio configuration
    ./brave # Brave browser profile with proxy
    ./tailscale # Tailscale status bar integration
    ./ssh # SSH client configuration
    ./discord # Discord/Vesktop theming via nixcord
    ./spicetify # Spotify customization via spicetify-nix
    ./terminal # Alacritty terminal emulator
    ./thunar # Thunar file manager custom actions
    ./nvf # Neovim via NVF framework
    ./isolation # Application isolation wrappers
    ./t3code # T3 Code AI editor
    ./zoom # Zoom video conferencing
    ./activitywatch # ActivityWatch time tracking
  ];
}
