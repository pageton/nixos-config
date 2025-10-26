# Hyprpanel is the bar on top of the screen
# Display information like workspaces, battery, wifi, ...
{
  lib,
  config,
  user,
  ...
}:
let
  transparentButtons = config.theme.bar.transparentButtons;

  accent = "#${config.lib.stylix.colors.base0D}";
  accent-alt = "#${config.lib.stylix.colors.base03}";
  background = "#${config.lib.stylix.colors.base00}";
  background-alt = "#${config.lib.stylix.colors.base01}";
  foreground = "#${config.lib.stylix.colors.base05}";
  foregroundOnWallpaper = "#${config.theme.textColorOnWallpaper}";
  font = "${config.stylix.fonts.serif.name}";
  fontSizeForHyprpanel = "${toString config.stylix.fonts.sizes.desktop}px";

  rounding = config.theme.rounding;
  border-size = config.theme.border-size;

  gaps-out = config.theme.gaps-out;
  gaps-in = config.theme.gaps-in;

  floating = config.theme.bar.floating;
  transparent = config.theme.bar.transparent;
  position = config.theme.bar.position; # "top" ou "bottom"

  notificationOpacity = 90;

  homeDir = "/home/${user}";
  hostname = builtins.getEnv "HOSTNAME";
  isThinkpad = hostname == "thinkpad";

in
{
  wayland.windowManager.hyprland.settings.exec-once = [ "hyprpanel" ];

  programs.hyprpanel = {
    enable = true;

    settings = {

      bar.layouts = lib.mkForce {
        "*" = lib.mkForce {
          left = lib.mkForce [
            "dashboard"
            "workspaces"
            "windowtitle"
          ];
          middle = lib.mkForce [
            "media"
            "cava"
          ];
          right = lib.mkForce (
            [
              "systray"
              "volume"
              "bluetooth"
            ]
            ++ (if isThinkpad then [ "battery" ] else [ ])
            ++ [
              "network"
              "clock"
              "notifications"
            ]
          );
        };
      };

      theme.font.name = lib.mkForce font;
      theme.font.size = lib.mkForce fontSizeForHyprpanel;

      theme.bar.outer_spacing = lib.mkForce (if floating && transparent then "0px" else "8px");
      theme.bar.buttons.y_margins = lib.mkForce (if floating && transparent then "0px" else "8px");
      theme.bar.buttons.spacing = lib.mkForce "0.3em";
      theme.bar.buttons.radius = lib.mkForce (
        (if transparent then toString rounding else toString (rounding - 8)) + "px"
      );
      theme.bar.floating = lib.mkForce floating;
      theme.bar.buttons.padding_x = lib.mkForce "0.8rem";
      theme.bar.buttons.padding_y = lib.mkForce "0.4rem";

      theme.bar.margin_top = lib.mkForce (
        (if position == "top" then toString (gaps-in * 2) else "0") + "px"
      );
      theme.bar.margin_bottom = lib.mkForce (
        (if position == "top" then "0" else toString (gaps-in * 2)) + "px"
      );
      theme.bar.margin_sides = lib.mkForce (toString gaps-out + "px");
      theme.bar.border_radius = lib.mkForce (toString rounding + "px");
      theme.bar.transparent = lib.mkForce transparent;
      theme.bar.location = lib.mkForce position;
      theme.bar.dropdownGap = lib.mkForce "4.5em";
      theme.bar.menus.shadow = lib.mkForce (if transparent then "0 0 0 0" else "0px 0px 3px 1px #16161e");
      theme.bar.buttons.style = lib.mkForce "default";
      theme.bar.buttons.monochrome = lib.mkForce true;
      theme.bar.menus.monochrome = lib.mkForce true;
      theme.bar.menus.card_radius = lib.mkForce (toString rounding + "px");
      theme.bar.menus.border.size = lib.mkForce (toString border-size + "px");
      theme.bar.menus.border.radius = lib.mkForce (toString rounding + "px");
      theme.bar.menus.menu.media.card.tint = lib.mkForce 90;

      bar.launcher.icon = lib.mkForce "";
      bar.workspaces.show_numbered = lib.mkForce false;
      bar.workspaces.workspaces = lib.mkForce 5;
      bar.workspaces.numbered_active_indicator = lib.mkForce "color";
      bar.workspaces.monitorSpecific = lib.mkForce false;
      bar.workspaces.applicationIconEmptyWorkspace = lib.mkForce "";
      bar.workspaces.showApplicationIcons = lib.mkForce true;
      bar.workspaces.showWsIcons = lib.mkForce true;

      bar.windowtitle.label = lib.mkForce true;
      bar.volume.label = lib.mkForce false;
      bar.network.truncation_size = lib.mkForce 12;
      bar.bluetooth.label = lib.mkForce false;
      bar.clock.format = lib.mkForce "%a %b %d  %I:%M %p";
      bar.notifications.show_total = lib.mkForce true;
      bar.media.show_active_only = lib.mkForce true;

      bar.customModules.updates.pollingInterval = lib.mkForce 1440000;
      bar.customModules.cava.showIcon = lib.mkForce false;
      bar.customModules.cava.stereo = lib.mkForce true;
      bar.customModules.cava.showActiveOnly = lib.mkForce true;

      notifications.position = lib.mkForce "top right";
      notifications.showActionsOnHover = lib.mkForce true;
      theme.notification.opacity = lib.mkForce notificationOpacity;
      theme.notification.enableShadow = lib.mkForce true;
      theme.notification.border_radius = lib.mkForce (toString rounding + "px");

      theme.osd.enable = lib.mkForce true;
      theme.osd.orientation = lib.mkForce "vertical";
      theme.osd.location = lib.mkForce "left";
      theme.osd.radius = lib.mkForce (toString rounding + "px");
      theme.osd.margins = lib.mkForce "0px 0px 0px 10px";
      theme.osd.muted_zero = lib.mkForce true;

      menus.clock.weather.unit = lib.mkForce "metric";
      menus.dashboard.powermenu.confirmation = lib.mkForce false;
      menus.dashboard.powermenu.avatar.image = lib.mkForce "~/.face.icon";

      menus.dashboard.shortcuts.left.shortcut1.icon = lib.mkForce "";
      menus.dashboard.shortcuts.left.shortcut1.command = lib.mkForce "brave";
      menus.dashboard.shortcuts.left.shortcut1.tooltip = lib.mkForce "Brave";
      menus.dashboard.shortcuts.left.shortcut2.icon = lib.mkForce "󰅶";
      menus.dashboard.shortcuts.left.shortcut2.command = lib.mkForce "caffeine";
      menus.dashboard.shortcuts.left.shortcut2.tooltip = lib.mkForce "Caffeine";
      menus.dashboard.shortcuts.left.shortcut3.icon = lib.mkForce "󰖔";
      menus.dashboard.shortcuts.left.shortcut3.command = lib.mkForce "night-shift";
      menus.dashboard.shortcuts.left.shortcut3.tooltip = lib.mkForce "Night-shift";
      menus.dashboard.shortcuts.left.shortcut4.icon = lib.mkForce "";
      menus.dashboard.shortcuts.left.shortcut4.command = lib.mkForce "menu";
      menus.dashboard.shortcuts.left.shortcut4.tooltip = lib.mkForce "Search Apps";

      menus.dashboard.shortcuts.right.shortcut1.icon = lib.mkForce "";
      menus.dashboard.shortcuts.right.shortcut1.command = lib.mkForce "hyprpicker -a";
      menus.dashboard.shortcuts.right.shortcut1.tooltip = lib.mkForce "Color Picker";

      menus.dashboard.shortcuts.right.shortcut3.icon = lib.mkForce "󰄀";
      menus.dashboard.shortcuts.right.shortcut3.command = lib.mkForce "screenshot region swappy";
      menus.dashboard.shortcuts.right.shortcut3.tooltip = lib.mkForce "Screenshot";

      menus.dashboard.directories.left.directory1.label = lib.mkForce "     Home";
      menus.dashboard.directories.left.directory1.command = lib.mkForce "xdg-open ${homeDir}";

      menus.dashboard.directories.left.directory2.label = lib.mkForce "󰲂     Documents";
      menus.dashboard.directories.left.directory2.command = lib.mkForce "xdg-open ${homeDir}/Documents";

      menus.dashboard.directories.left.directory3.label = lib.mkForce "󰉍     Downloads";
      menus.dashboard.directories.left.directory3.command = lib.mkForce "xdg-open ${homeDir}/Downloads";

      menus.dashboard.directories.right.directory1.label = lib.mkForce "     Desktop";
      menus.dashboard.directories.right.directory1.command = lib.mkForce "xdg-open ${homeDir}/Desktop";

      menus.dashboard.directories.right.directory2.label = lib.mkForce "     Videos";
      menus.dashboard.directories.right.directory2.command = lib.mkForce "xdg-open ${homeDir}/Videos";

      menus.dashboard.directories.right.directory3.label = lib.mkForce "󰉏     Pictures";
      menus.dashboard.directories.right.directory3.command = lib.mkForce "xdg-open ${homeDir}/Pictures";

      menus.power.lowBatteryNotification = lib.mkForce true;

      wallpaper.enable = lib.mkForce false;

      theme.bar.buttons.workspaces.hover = lib.mkForce accent-alt;
      theme.bar.buttons.workspaces.active = lib.mkForce accent;
      theme.bar.buttons.workspaces.available = lib.mkForce accent-alt;
      theme.bar.buttons.workspaces.occupied = lib.mkForce accent-alt;

      theme.bar.menus.background = lib.mkForce background;
      theme.bar.menus.cards = lib.mkForce background-alt;
      theme.bar.menus.label = lib.mkForce foreground;
      theme.bar.menus.text = lib.mkForce foreground;
      theme.bar.menus.border.color = lib.mkForce accent;
      theme.bar.menus.popover.text = lib.mkForce foreground;
      theme.bar.menus.popover.background = lib.mkForce background-alt;
      theme.bar.menus.listitems.active = lib.mkForce accent;
      theme.bar.menus.icons.active = lib.mkForce accent;
      theme.bar.menus.switch.enabled = lib.mkForce accent;
      theme.bar.menus.check_radio_button.active = lib.mkForce accent;
      theme.bar.menus.buttons.default = lib.mkForce accent;
      theme.bar.menus.buttons.active = lib.mkForce accent;
      theme.bar.menus.iconbuttons.active = lib.mkForce accent;
      theme.bar.menus.progressbar.foreground = lib.mkForce accent;
      theme.bar.menus.slider.primary = lib.mkForce accent;
      theme.bar.menus.tooltip.background = lib.mkForce background-alt;
      theme.bar.menus.tooltip.text = lib.mkForce foreground;
      theme.bar.menus.dropdownmenu.background = lib.mkForce background-alt;
      theme.bar.menus.dropdownmenu.text = lib.mkForce foreground;

      theme.bar.background = lib.mkForce (
        background + (if transparentButtons && transparent then "00" else "")
      );
      theme.bar.buttons.text = lib.mkForce (
        if transparent && transparentButtons then foregroundOnWallpaper else foreground
      );
      theme.bar.buttons.background = lib.mkForce (
        (if transparent then background else background-alt) + (if transparentButtons then "00" else "")
      );
      theme.bar.buttons.icon = lib.mkForce accent;

      theme.bar.buttons.notifications.background = lib.mkForce background-alt;
      theme.bar.buttons.hover = lib.mkForce background;
      theme.bar.buttons.notifications.hover = lib.mkForce background;
      theme.bar.buttons.notifications.total = lib.mkForce accent;
      theme.bar.buttons.notifications.icon = lib.mkForce accent;

      theme.osd.bar_color = lib.mkForce accent;
      theme.osd.bar_overflow_color = lib.mkForce accent-alt;
      theme.osd.icon = lib.mkForce background;
      theme.osd.icon_container = lib.mkForce accent;
      theme.osd.label = lib.mkForce accent;
      theme.osd.bar_container = lib.mkForce background-alt;

      theme.bar.menus.menu.media.background.color = lib.mkForce background-alt;
      theme.bar.menus.menu.media.card.color = lib.mkForce background-alt;

      theme.notification.background = lib.mkForce background-alt;
      theme.notification.actions.background = lib.mkForce accent;
      theme.notification.actions.text = lib.mkForce foreground;
      theme.notification.label = lib.mkForce accent;
      theme.notification.border = lib.mkForce background-alt;
      theme.notification.text = lib.mkForce foreground;
      theme.notification.labelicon = lib.mkForce accent;
      theme.notification.close_button.background = lib.mkForce background-alt;
      theme.notification.close_button.label = lib.mkForce "#f38ba8";
    };
  };
}
