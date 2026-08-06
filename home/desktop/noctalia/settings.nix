# Noctalia v5 declarative settings (Nix attrset -> TOML via the HM module).
#
# v5 has NO Stylix target (v4 had noctalia-shell.enable). We hand-mirror the
# Catppuccin Mocha palette + wallpaper here. v5's two-layer model: this TOML is
# the base; GUI overrides land in ~/.local/state/noctalia/settings.toml (which
# already exists at config_version 12 and is preserved).
{
  config,
  inputs,
  pkgs,
  system,
  ...
}:
let
  palette = import ../../themes/palette.nix;
  # Reuse the exact stylix-managed nix-wallpaper derivation as the wallpaper
  # source — single source of truth, matches the login/desktop/screenshot bg.
  wallpaper = inputs.nix-wallpaper.packages.${system}.default.override {
    backgroundColor = "#${palette.base00}";
    logoColors = {
      color0 = "#${palette.base0D}"; # Blue
      color1 = "#${palette.base0E}"; # Mauve
      color2 = "#${palette.base0C}"; # Teal
      color3 = "#${palette.base09}"; # Peach
      color4 = "#${palette.base0B}"; # Green
      color5 = "#${palette.base0F}"; # Pink
    };
  };
in
{
  programs.noctalia.settings = {
    # === Theme ===
    # v5 ships Catppuccin as a builtin palette; mode "dark" matches stylix.polarity.
    theme = {
      mode = "dark"; # dark | light | auto
      source = "builtin"; # builtin | wallpaper | community
      builtin = "Catppuccin"; # Ayu | Catppuccin | Dracula | Eldritch | Gruvbox | ...
      pure_black_dark = false; # anchor dark surfaces to true black (OLED)
    };

    # === Wallpaper ===
    # Same nix-wallpaper derivation stylix uses (home/themes/stylix.nix).
    # default.path is the per-output fallback; v5 also supports a wallpaper
    # directory for rotation (left at v5 defaults — configure via GUI later).
    wallpaper = {
      enabled = true;
      fill_mode = "crop"; # center | crop | fit | stretch | repeat | span
      default.path = "${wallpaper}/share/wallpapers/nixos-wallpaper.png";
    };

    # === Shell defaults ===
    # Minimal: only set keys that differ from v5 defaults or that we want pinned.
    # The existing GUI state layer (~/.local/state/noctalia/settings.toml) holds
    # the rest (lockscreen widget layout, etc.) and is preserved across switches.
    shell = {
      # Keep v5's built-in clipboard manager on (replaces the v4 QML clipboard
      # plugin's pin/copy affordances with the native panel for now).
      clipboard_enabled = true;
      font_family = config.stylix.fonts.monospace.name;
      app_icon_colorize = false;
      session = {
        grid = true;
        grid_columns = 3;
      };
    };

    # === Bar ===
    # Compact full-width layout modelled after the reference: time, live stats,
    # media, and the active window on the left; workspaces in the centre; and a
    # dense status cluster on the right.
    bar = {
      order = [ "default" ];

      default = {
        enabled = true;
        position = "top";
        thickness = 40;
        background_opacity = 0.92;
        border_width = 0.0;
        radius = 6;
        concave_edge_corners = false;
        margin_ends = 6;
        margin_edge = 6;
        padding = 12;
        widget_spacing = 10;
        scale = 1.0;
        font_weight = 500;
        font_family = config.stylix.fonts.monospace.name;
        shadow = false;
        reserve_space = true;
        capsule = false;
        capsule_thickness = 0.8;
        hover_highlight = true;

        start = [
          "clock-compact"
          "group:system-metrics"
          "media-compact"
          "active-window"
        ];
        center = [ "workspaces-compact" ];
        end = [
          "tray-compact"
          "network-compact"
          "notifications"
          "launcher"
          "bluetooth"
          "battery-compact"
          "volume-compact"
          "control-center"
          "session"
        ];

        capsule_group = [
          {
            id = "system-metrics";
            members = [
              "cpu-usage"
              "cpu-temperature"
              "memory-used"
              "network-rx"
              "network-tx"
              "disk-used"
            ];
            enabled = true;
            fill = "surface_variant";
            foreground = "on_surface";
            opacity = 0.58;
            padding = 8.0;
            radius = 15.0;
            widget_spacing = 8.0;
          }
        ];

        # The 1080p secondary display has less horizontal room. Keep media in
        # the left lane and drop the redundant active-window capsule there so
        # long track titles cannot collide with the centred workspaces.
        monitor."DP-4" = {
          match = "DP-4";
          start = [
            "clock-compact"
            "group:system-metrics"
            "media-compact"
          ];
          center = [ "workspaces-compact" ];
        };
      };
    };

    system.monitor.enabled = true;

    widget = {
      clock-compact = {
        type = "clock";
        format = "{:%I:%M %p %a, %b %d}";
        tooltip_format = "{:%A, %B %d, %Y}";
        capsule = true;
        capsule_fill = "surface_variant";
        capsule_opacity = 0.68;
        capsule_padding = 10;
        capsule_radius = 15.0;
      };

      cpu-usage = {
        type = "sysmon";
        stat = "cpu_usage";
        visualization = "gauge";
        show_glyph = false;
        show_value = true;
        label_show_units = true;
      };
      cpu-temperature = {
        type = "sysmon";
        stat = "cpu_temp";
        visualization = "none";
        show_glyph = true;
        show_value = true;
        label_show_units = true;
      };
      memory-used = {
        type = "sysmon";
        stat = "ram_used";
        visualization = "none";
        show_glyph = true;
        show_value = true;
        label_show_units = true;
      };
      network-rx = {
        type = "sysmon";
        stat = "net_rx";
        visualization = "none";
        show_glyph = true;
        show_value = true;
        label_show_units = true;
        network_speed_compact = true;
      };
      network-tx = {
        type = "sysmon";
        stat = "net_tx";
        visualization = "none";
        show_glyph = true;
        show_value = true;
        label_show_units = true;
        network_speed_compact = true;
      };
      disk-used = {
        type = "sysmon";
        stat = "disk_used";
        path = "/";
        visualization = "none";
        show_glyph = true;
        show_value = true;
        label_show_units = true;
      };

      active-window = {
        type = "active_window";
        display = "icon_and_text";
        min_length = 100;
        max_length = 220;
        icon_size = 18;
        title_scroll = "on_hover";
        capsule = true;
        capsule_fill = "surface_variant";
        capsule_opacity = 0.68;
        capsule_padding = 9;
        capsule_radius = 15.0;
      };
      workspaces-compact = {
        type = "taskbar";
        scale = 1.25;
        group_by_workspace = true;
        only_active_workspace = false;
        hide_empty_workspaces = false;
        workspace_group_content = "icons";
        group_single_icon_per_app = true;
        workspace_group_capsule = true;
        show_workspace_label = false;
        show_active_indicator = true;
        active_indicator_color = "#${palette.base0D}";
        active_opacity = 1.0;
        inactive_opacity = 0.72;
        focused_color = "#${palette.base0E}";
        occupied_color = "#${palette.base0C}";
        empty_color = "#${palette.base04}";
        urgent_color = "#${palette.base08}";
        capsule = false;
        capsule_radius = 15.0;
      };

      media-compact = {
        type = "media";
        min_length = 80;
        max_length = 180;
        art_size = 18;
        title_scroll = "on_hover";
        hide_when_no_media = true;
        capsule = true;
        capsule_fill = "surface_variant";
        capsule_opacity = 0.68;
        capsule_padding = 9;
        capsule_radius = 15.0;
      };
      tray-compact = {
        type = "tray";
        drawer = true;
        match_adjacent_spacing = true;
        drawer_columns = 4;
      };
      network-compact = {
        type = "network";
        show_label = false;
        show_vpn_label = false;
        vpn_status = "replace";
      };
      battery-compact = {
        type = "battery";
        display_mode = "glyph";
        show_label = false;
        hide_when_full = false;
      };
      volume-compact = {
        type = "volume";
        show_label = false;
      };
      control-center = {
        custom_image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        custom_image_colorize = false;
      };
    };
  };
}
