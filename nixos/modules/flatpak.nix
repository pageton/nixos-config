# Flatpak configuration for sandboxed application distribution.
{ config, lib, ... }: {
  # Custom module options for Flatpak configuration
  options.mySystem.flatpak = {
    enable = lib.mkEnableOption "Flatpak support for sandboxed applications";
  };

  # Configuration applied when Flatpak is enabled
  config = lib.mkIf config.mySystem.flatpak.enable {
    # Enable Flatpak service
    services.flatpak.enable = true;

    mySystem.mullvadVpn.lanServices = [ "flatpak" ];

    # Configure Flatpak to use Flathub as the default remote
    systemd.services.add-flathub = {
      description = "Add Flathub remote";
      wantedBy = [ "multi-user.target" ];
      # network-online.target (not just network.target) waits for connectivity,
      # avoiding a race where the remote-add runs before DNS is resolvable.
      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
        "flatpak-system.service"
      ];
      path = [ config.services.flatpak.package ];
      script = ''
        url="https://flathub.org/repo/flathub.flatpakrepo"
        for i in 1 2 3 4 5; do
          if flatpak remote-add --if-not-exists flathub "$url"; then
            exit 0
          fi
          echo "add-flathub: attempt $i failed, retrying in 5s..." >&2
          sleep 5
        done
        echo "add-flathub: giving up after 5 attempts" >&2
        exit 1
      '';
      serviceConfig = {
        Type = "oneshot";
        # Don't let a flaky boot network gate the whole activation.
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
