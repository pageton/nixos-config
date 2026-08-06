# Noctalia v5 declarative settings (Nix attrset -> TOML via the HM module).
#
# v5 has NO Stylix target (v4 had noctalia-shell.enable). We hand-mirror the
# Catppuccin Mocha palette + wallpaper here. v5's two-layer model: this TOML is
# the base; GUI overrides land in ~/.local/state/noctalia/settings.toml (which
# already exists at config_version 12 and is preserved).
{
  config,
  inputs,
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
    };
  };
}
