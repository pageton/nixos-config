# Cloudflare WARP GUI — warp-taskbar tray applet.
#
# Talks to the warp-svc daemon enabled NixOS-side via mySystem.cloudflareWarp;
# enable this host-side in sync (only hosts running the daemon get the GUI).
#
# warp-taskbar is the GUI from Cloudflare's .deb: it resolves its resources
# under /usr/share/warp, so the store path is bind-mounted read-only over /usr
# exactly like the user unit nixpkgs ships in the package. User units support
# BindReadOnlyPaths via unprivileged user namespaces (kernel.unprivileged_userns_clone).
{
  hostname,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (hostname == "desktop") {
    systemd.user.services.warp-taskbar = {
      Unit = {
        Description = "Cloudflare WARP GUI (tray)";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.cloudflare-warp}/bin/warp-taskbar";
        BindReadOnlyPaths = [ "${pkgs.cloudflare-warp}:/usr:" ];
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
