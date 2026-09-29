# Home-Manager programs — application and tool configurations.
_: {
  imports = [
    ./languages # Language toolchains (Go, Python, Node.js, etc.)
    ./terminal # Terminal, shell, and CLI tools
    ./nvf # Neovim via NVF framework
    ./gpg.nix # GPG key management and agent
    ./git.nix # Git identity, GPG signing, and hooks
    ./obs.nix # OBS Studio configuration
    ./brave.nix # Brave browser with Wayland and extensions
    ./chromium.nix # Chromium launch wrapper with Wayland flags
    ./tailscale.nix # Tailscale VPN packages
    ./ssh.nix # SSH client configuration
    ./discord.nix # Discord/Vesktop theming via nixcord
    ./telegram.nix # Second Telegram Desktop instance (unsandboxed, separate profile)
    ./spicetify.nix # Spotify customization via spicetify-nix
    ./thunar.nix # Thunar file manager custom actions
    ./activitywatch.nix # ActivityWatch time tracking
  ];
}
