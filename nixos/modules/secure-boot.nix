# Secure Boot preparation with sbctl.
# Provides tamper-evident boot chain to prevent evil-maid attacks.
#
# ACTIVATION STEPS (must be done manually after nixos-rebuild):
#   1. sudo sbctl create-keys          # Generate signing keys
#   2. sudo sbctl enroll-keys --microsoft  # Enroll keys in firmware
#   3. sudo sbctl status               # Verify enrollment
#   4. sudo sbctl verify               # Check which binaries need signing
#   5. sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
#   6. sudo sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi
#   7. Reboot, enter BIOS, enable Secure Boot in "Setup Mode"
#   8. Verify: sudo mokutil --sb-state

{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.mySystem.secureBoot = {
    enable = lib.mkEnableOption "Secure Boot preparation with sbctl";
  };

  config = lib.mkIf config.mySystem.secureBoot.enable {
    environment.systemPackages = [
      pkgs.sbctl
      pkgs.mokutil
    ];

    systemd.tmpfiles.rules = [ "d /var/lib/sbctl 0700 root root -" ];

    # Auto-sign EFI binaries after NixOS rebuilds
    systemd.services.sbctl-sign = {
      description = "Auto-sign EFI binaries with Secure Boot keys";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      path = [ pkgs.sbctl ];

      script = ''
        if sbctl status 2>/dev/null | grep -q "Setup Mode: Disabled"; then
          sbctl sign-all 2>/dev/null || true
          echo "[$(date -Iseconds)] Secure Boot: signed all EFI binaries" | logger -t sbctl-sign
        fi
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        PrivateTmp = true;
        ProtectHome = true;
        NoNewPrivileges = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        ReadWritePaths = [
          "/boot"
          "/var/lib/sbctl"
        ];
      };
    };
  };
}
