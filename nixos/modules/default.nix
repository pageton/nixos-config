# Root NixOS module loader.
#
# Architecture: Two-level import pattern.
#   1. This file imports category directories (core/, hardware/, etc.).
#   2. Each directory's default.nix imports flat .nix files from the parent
#      directory using relative paths (e.g., ../bootloader.nix).
#
# Flat files live at this level (nixos/modules/*.nix) for discoverability.
# They are organized into categories via the subdirectory imports below.
#
# Adding a new module:
#   1. Create nixos/modules/my-module.nix with option definitions under mySystem.*
#   2. Import it from the appropriate category default.nix (e.g., core/default.nix)
#   3. Enable it in the host configuration (hosts/<name>/configuration.nix)
{
  # modules-check: subdir-loader
  imports = [
    ./core # Bootloader, Nix, users, SOPS, timezone, i18n, environment, stability, validation
    ./hardware # Audio, Bluetooth, Graphics (NVIDIA), Input, Power, Thermal, Android
    ./desktop # Niri compositor, SDDM, X11 disabled, XDG portals
    ./network # NetworkManager, DNSCrypt, Mullvad VPN, Tailscale, Tor
    ./security-stack # Kernel/sysctl hardening, Firejail sandboxing, OpenSnitch, MAC randomization
    ./apps # Browser deps, Flatpak, Gaming, KDE Connect, Syncthing
    ./virtualization # Docker, VirtualBox, libvirt, Waydroid, nix-ld
    ./observability # Monitoring, Netdata, Scrutiny, Glance, Loki
    ./performance # Boot optimization
    ./maintenance # Cleanup timers, Restic backup, nh
  ];
}
