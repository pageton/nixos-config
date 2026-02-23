# Networking configuration module.
# NOTE: Firewall rules live in security.nix to keep all hardening in one place.
{
  lib,
  ...
}: {
  # NetworkManager for GUI networking
  networking.networkmanager.enable = lib.mkDefault true;

  # SSH server — key-only auth, password disabled
  # Access control: firewall (security.nix) + Tailscale ACLs
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
