# Flatpak configuration for sandboxed application distribution.
{
  config,
  lib,
  ...
}: {
  # Custom module options for Flatpak configuration
  options.mySystem.flatpak = {
    enable = lib.mkEnableOption "Flatpak support for sandboxed applications";
  };

  # Configuration applied when Flatpak is enabled
  config = lib.mkIf config.mySystem.flatpak.enable {
    # Enable Flatpak service
    services.flatpak.enable = true;

    # Configure Flatpak to use Flathub as the default remote
    systemd.services.add-flathub = {
      description = "Add Flathub remote";
      wantedBy = ["multi-user.target"];
      after = [
        "network.target"
        "flatpak-system.service"
      ];
      path = [config.services.flatpak.package];
      script = ''
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      '';
    };
  };
}
