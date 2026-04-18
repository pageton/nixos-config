# VNC remote access (x11vnc, noVNC, websockify).
# SECURITY: x11vnc is UNENCRYPTED. Always tunnel through SSH.
{
  config,
  lib,
  pkgs,
  user,
  constants,
  ...
}:
{
  options.mySystem.vnc = {
    enable = lib.mkEnableOption "VNC remote access with x11vnc, noVNC, and websockify";
  };

  config = lib.mkIf config.mySystem.vnc.enable {
    environment.systemPackages = with pkgs; [
      x11vnc
      novnc
      python3Packages.websockify
      xclip
    ];

    networking.firewall.extraCommands = ''
      iptables -A INPUT -p tcp --dport ${toString constants.ports.vnc} -s 127.0.0.1 -j ACCEPT
      iptables -A INPUT -p tcp --dport ${toString constants.ports.vnc} -j DROP
      iptables -A INPUT -p tcp --dport ${toString constants.ports.vnc-web} -s 127.0.0.1 -j ACCEPT
      iptables -A INPUT -p tcp --dport ${toString constants.ports.vnc-web} -j DROP
    '';
  };
}
