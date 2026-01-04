# MAC address randomization for privacy.
# Automatically randomizes MAC addresses on network interfaces at startup.
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Custom module options for MAC changer configuration
  options.mySystem.macchanger = {
    enable = lib.mkEnableOption "MAC address randomization on network interfaces at startup";
  };

  # Configuration applied when MAC changer is enabled
  config = lib.mkIf config.mySystem.macchanger.enable {
    # Install macchanger package
    environment.systemPackages = with pkgs; [macchanger];

    # Systemd service to randomize MAC on boot
    systemd.services.macchanger = {
      description = "Randomize MAC addresses on network interfaces";
      wantedBy = ["network-pre.target"];
      before = [
        "NetworkManager.service"
        "network.target"
      ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "macchanger-startup" ''
          #!${pkgs.bash}/bin/bash
          # Randomize MAC for all ethernet and wifi interfaces
          for iface in /sys/class/net/*; do
            name=$(basename "$iface")
            # Skip loopback and docker interfaces
            case "$name" in
              lo|docker*|veth*|br-*) continue ;;
            esac
            # Check if interface is ethernet or wireless
            if [ -d "$iface/wireless" ] || [ -d "$iface/phy80211" ]; then
              echo "Randomizing MAC for wireless interface: $name"
              ${pkgs.iproute2}/bin/ip link set "$name" down 2>/dev/null || true
              ${pkgs.macchanger}/bin/macchanger -a "$name" 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip link set "$name" up 2>/dev/null || true
            elif [ -d "$iface/device" ]; then
              echo "Randomizing MAC for ethernet interface: $name"
              ${pkgs.iproute2}/bin/ip link set "$name" down 2>/dev/null || true
              ${pkgs.macchanger}/bin/macchanger -a "$name" 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip link set "$name" up 2>/dev/null || true
            fi
          done
        '';
        RemainAfterExit = "yes";
      };
    };
  };
}
