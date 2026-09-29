# MAC address randomization for privacy.
# Randomizes MAC addresses on all ethernet/wireless interfaces at startup.
{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [ macchanger ];

  systemd.services.macchanger = {
    description = "Randomize MAC addresses on network interfaces";
    wantedBy = [ "network-pre.target" ];
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
}
