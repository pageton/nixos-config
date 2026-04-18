# Mullvad VPN with hardened tunnel settings.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.mySystem.mullvadVpn = {
    enable = lib.mkEnableOption "Mullvad VPN service";
  };

  config = lib.mkIf config.mySystem.mullvadVpn.enable {
    services.mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn; # Includes GUI
    };

    # Mullvad's packaged unit waits for network-online, which adds ~14s of
    # boot delay via NetworkManager-wait-online. Starting after NetworkManager
    # is sufficient; the daemon can reconnect as soon as the link is usable.
    systemd.services.mullvad-daemon = {
      wants = lib.mkForce [ "network.target" ];
      after = lib.mkForce [
        "network.target"
        "NetworkManager.service"
      ];
    };

    # Declarative settings applied after daemon starts
    systemd.services.mullvad-settings = {
      description = "Apply declarative Mullvad VPN settings";
      after = [ "mullvad-daemon.service" ];
      requires = [ "mullvad-daemon.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mullvad=${pkgs.mullvad}/bin/mullvad

        # Wait for mullvad daemon RPC socket to be ready
        for i in $(seq 1 30); do
          $mullvad status >/dev/null 2>&1 && break
          sleep 1
        done

        # Wait for relay cache (daemon needs network to fetch it)
        for i in $(seq 1 30); do
          $mullvad relay list 2>/dev/null | grep -q "WireGuard" && break
          sleep 2
        done

        # === DNS ===
        $mullvad dns set default || true

        # === Kill Switch ===
        $mullvad lockdown-mode set on || true

        # === Auto-connect ===
        $mullvad auto-connect set on || true

        # === Relay Selection ===
        $mullvad relay set multihop off || true
        $mullvad relay set location il || true

        # === Tunnel Hardening ===
        $mullvad tunnel set quantum-resistant on || true
        $mullvad tunnel set daita off || true
        $mullvad tunnel set ipv6 off || true
        $mullvad tunnel set rotation-interval 24 || true

        # === Obfuscation ===
        $mullvad obfuscation set mode auto || true

        # === Local Network ===
        ${
          if
            (
              config.mySystem.kdeconnect.enable or false
              || config.mySystem.flatpak.enable or false
              || config.mySystem.virtualisation.enable or false
            )
          then
            ''
              $mullvad lan set allow || true
            ''
          else
            ''
              $mullvad lan set block || true
            ''
        }
      '';
    };
  };
}
