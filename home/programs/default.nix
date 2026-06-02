# Home-Manager programs — application and tool configurations.
_: {
  imports = [
    ./ai-agents # AI coding agent wrappers, launchers, and log analysis
    ./languages # Language toolchains (Go, Python, Node.js, etc.)
    ./terminal # Terminal, shell, and CLI tools
    ./nvf # Neovim via NVF framework
    ./librewolf # LibreWolf browser with multi-profile proxy setup
    ./isolation # Application isolation wrappers
    ./gpg.nix # GPG key management and agent
    ./obs.nix # OBS Studio configuration
    ./brave.nix # Brave browser with Wayland and extensions
    ./chromium.nix # Chromium launch wrapper with Wayland flags
    ./tailscale.nix # Tailscale VPN packages
    ./ssh.nix # SSH client configuration
    ./discord.nix # Discord/Vesktop theming via nixcord
    ./spicetify.nix # Spotify customization via spicetify-nix
    ./thunar.nix # Thunar file manager custom actions
    ./activitywatch.nix # ActivityWatch time tracking
  ];
}
