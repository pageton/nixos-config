# Nix Helper (nh) - Simple configuration module.
# Installs nh and sets up basic environment for better NixOS management.
{
  pkgs,
  user,
  ...
}:
let
  nixValidate = pkgs.writeShellApplication {
    name = "nix-validate";
    runtimeInputs = [ pkgs.nix ];
    text = ''
      set -euo pipefail

      FLAKE_DIR="''${NH_FLAKE:-/home/${user}/System}"
      cd "$FLAKE_DIR"

      echo "==> flake check (no build)"
      nix flake check --no-build

      echo "==> evaluating host configs"
      nix eval .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath >/dev/null
      nix eval .#nixosConfigurations.thinkpad.config.system.build.toplevel.drvPath >/dev/null

      echo "==> evaluating home-manager configs"
      nix eval .#homeConfigurations.${user}@desktop.activationPackage.drvPath >/dev/null
      nix eval .#homeConfigurations.${user}@thinkpad.activationPackage.drvPath >/dev/null

      echo "OK: flake checks and evaluations passed"
    '';
  };
in
{
  # Simple nh configuration - just install and setup environment
  environment = {
    # Install nh package
    systemPackages = with pkgs; [
      nh
      nixValidate
    ];

    # Set FLAKE environment variable using user from flake
    sessionVariables = {
      NH_FLAKE = "/home/${user}/System";
    };
  };

  # Basic nh directories
  systemd.tmpfiles.rules = [ "d /var/cache/nh 0755 root root -" ];
}
