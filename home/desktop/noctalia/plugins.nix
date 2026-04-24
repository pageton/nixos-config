{ ... }:
{
  programs.noctalia-shell = {
    plugins = {
      version = 2;
      sources = [
        {
          enabled = true;
          name = "Noctalia Plugins";
          url = "https://github.com/noctalia-dev/noctalia-plugins";
        }
      ];
      states = {
        tailscale = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        screen-toolkit = {
          enabled = false;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        port-monitor = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        usb-drive-manager = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        ip-monitor = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        polkit-agent = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
      };
    };

    pluginSettings = {
      usb-drive-manager = {
        autoMount = false;
        fileBrowser = "yazi";
        notifications = true;
        hideWhenEmpty = false;
      };
      port-monitor = {
        refreshInterval = 5;
        hideSystemPorts = false;
        hideWhenEmpty = false;
      };
      screen-toolkit = {
        screenshotPath = "~/Pictures/Screenshots";
        videoPath = "~/Videos";
        filenameFormat = "{prefix}-{date}_{time}";
      };
      tailscale = {
        refreshInterval = 5000;
        compactMode = true;
        showIpAddress = true;
        showPeerCount = true;
        terminalCommand = "alacritty";
      };
    };
  };
}
