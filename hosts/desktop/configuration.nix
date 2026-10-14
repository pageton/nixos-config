# Main NixOS configuration for the 'desktop' host.
# Tower: Ryzen 5 7600X + dedicated NVIDIA GPU + AMD thermal watchdog.
{
  stateVersion,
  hostname,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/profiles/common.nix

    # Desktop-only features
    ../../nixos/modules/amd-thermal.nix
    ../../nixos/modules/cloudflared.nix
    ../../nixos/modules/cloudflare-warp.nix
    ../../nixos/modules/gaming.nix
    ../../nixos/modules/loki.nix
    ../../nixos/modules/mullvad.nix
    ../../nixos/modules/observability
    ../../nixos/modules/vaultwarden.nix
    ../../nixos/modules/virtualisation.nix
  ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;

  # ThinkPad-only behaviors that the shared modules default differently:
  # (none — desktop uses the shared defaults, e.g. bluetooth powerOnBoot = true)
}
