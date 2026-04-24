{
  hostname,
  lib,
  ...
}: let
  isThinkpad = hostname == "thinkpad";
in {
  programs.noctalia-shell.settings.bar = {
    position = "top";
    floating = true;
    density = "comfortable";
    backgroundOpacity = lib.mkForce 0.95;

    widgets = {
      left = [
        {
          id = "Clock";
          formatHorizontal = "hh:mm A ddd, MMM dd";
        }
        {
          id = "SystemMonitor";
          compactMode = false;
          showGpuTemp = true;
          showNetworkStats = true;
          showDiskUsage = true;
        }
        {id = "ActiveWindow";}
        {id = "MediaMini";}
      ];
      center = [
        {
          id = "Workspace";
          showApplications = true;
          labelMode = "index";
          hideUnoccupied = false;
          showLabelsOnlyWhenOccupied = true;
          colorizeIcons = false;
          iconScale = 0.8;
          showBadge = true;
          enableScrollWheel = true;
          focusedColor = "tertiary";
          occupiedColor = "secondary";
          emptyColor = "secondary";
        }
      ];
      right =
        [
          {id = "Tray";}
          {id = "Network";}
          {id = "NotificationHistory";}
          {id = "plugin:tailscale";}
          {id = "plugin:usb-drive-manager";}
          {id = "Battery";}
          {id = "Volume";}
        ]
        ++ lib.optionals isThinkpad [{id = "Brightness";}]
        ++ [
          {
            id = "ControlCenter";
            useDistroLogo = false;
            icon = "settings";
          }
        ];
    };
  };
}
