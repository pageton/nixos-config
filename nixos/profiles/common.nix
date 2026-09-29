# Common profile — modules active on every host.
#
# Hosts import this plus any extra feature modules they need, e.g.:
#   ../../nixos/profiles/common.nix
#   ../../nixos/modules/gaming.nix
#
# There are no enable toggles: a module is active because it is imported.
# Machine-specific settings (PRIME bus IDs, TLP, kernel params) live in
# hosts/<name>/, not here.
{
  imports = [
    # Core
    ../modules/base.nix # Nix settings, overlays, locale, env, monitoring tools
    ../modules/boot.nix # GRUB + kernel
    ../modules/users.nix # User account + SSH keys
    ../modules/sops.nix # Secrets
    ../modules/tuning.nix # earlyoom, sysctl, PAM limits
    ../modules/opsec.nix # Session lock, NTS time, zram
    ../modules/security.nix # Hardening, firewall, AIDE, AppArmor
    ../modules/network.nix # NetworkManager, resolved, sshd
    ../modules/macchanger.nix # MAC randomization
    ../modules/validation.nix # Conflict assertions

    # Hardware
    ../modules/audio.nix # PipeWire + RNNoise
    ../modules/bluetooth.nix # BlueZ + Blueman
    ../modules/nvidia.nix # NVIDIA driver stack
    ../modules/android.nix # ADB / Android Studio

    # Desktop
    ../modules/desktop.nix # Niri, Noctalia Greeter, portals, xkb
    ../modules/browser-deps.nix # Chromium / Puppeteer deps

    # Sandbox / compat
    ../modules/sandboxing.nix # Firejail wrapped binaries
    ../modules/nix-ld.nix # Non-NixOS binaries

    # Services
    ../modules/flatpak.nix # Flathub
    ../modules/syncthing.nix # File sync
    ../modules/glance # Dashboard
    ../modules/netdata.nix # Metrics (boot-deferred)
    ../modules/scrutiny.nix # Disk health (boot-deferred)
    ../modules/tailscale.nix # Mesh VPN
    ../modules/tor.nix # Tor SOCKS/DNS
  ];
}
