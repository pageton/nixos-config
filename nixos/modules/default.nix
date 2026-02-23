# Imports all NixOS modules.
{
  imports = [
    # Core system
    ./bootloader.nix
    ./nix.nix
    ./users.nix
    ./timezone.nix
    ./i18n.nix
    ./environment.nix
    ./stability.nix
    ./validation.nix # Cross-module conflict assertions

    # Hardware
    ./audio.nix
    ./bluetooth.nix
    ./graphics.nix
    ./libinput.nix
    ./upower.nix

    # Desktop environment
    ./niri.nix
    ./sddm.nix
    ./xserver.nix
    ./xdg-desktop-portal.nix

    # Networking
    ./networking.nix
    ./dnscrypt-proxy.nix
    ./mullvad.nix
    ./tailscale.nix
    ./tor.nix

    # Security
    ./security.nix # Kernel hardening, firewall, AppArmor, opsec, AIDE
    ./sandboxing.nix # Firejail and bubblewrap sandboxing
    ./opensnitch.nix # Application firewall with network logging
    ./macchanger.nix

    # Applications
    ./browser-deps.nix
    ./flatpak.nix
    ./gaming.nix

    # Virtualisation
    ./virtualisation.nix
    ./nix-ld.nix

    # Monitoring and observability
    ./monitoring.nix
    ./scrutiny.nix # SMART disk health monitoring
    ./loki.nix # Loki log aggregation with Promtail

    # Boot optimization
    ./boot-optimization.nix # Defer monitoring services from blocking boot

    # Maintenance
    ./cleanup.nix
    ./backup.nix # Restic backups with retention
    ./nh.nix
  ];
}
