# Shared constants used across NixOS and Home Manager configurations.
# Single source of truth for terminal, editor, font, theme, and keyboard settings.
#
# Usage (in NixOS modules):
#   { constants, ... }:
#   { TERMINAL = constants.terminal; }
#
# Usage (in Home Manager modules):
#   { constants, ... }:
#   { config.programs.ghostty.settings.font-family = constants.font.mono; }

{
  # User Identity (Git, GitHub, Contact)
  user = {
    handle = "Sadiq";
    name = "Sadiq";
    email = "pageton@proton.me";
    signingKey = "5684AD6E4045F283";
  };

  # Terminal emulator
  terminal = "ghostty";
  terminalAppId = "com.mitchellh.ghostty";

  # Default text editor
  editor = "code";
  editorAppId = "code|Code|code-url-handler";

  # Fonts
  font = {
    mono = "JetBrains Mono Nerd Font";
    size = 13;
  };

  # Theme (Catppuccin Mocha)
  theme = "catppuccin-mocha";

  # Catppuccin Mocha color palette
  # Mapped to the same structure as the original for compatibility with ai-agents and other modules.
  # Base backgrounds use the user's custom darker variant from kanagawa.nix.
  color = {
    # Hard/Background shades (user's custom darker Mocha bases)
    bg_hard = "#0F0F15"; # base00 — darkest background
    bg = "#15151A"; # base01 — main background
    bg_soft = "#1e1e2e"; # Mocha Base — slightly lighter
    bg0 = "#313244"; # Surface0
    bg1 = "#45475a"; # Surface1

    # Foreground shades
    fg0 = "#cdd6f4"; # Text (primary foreground)
    fg_dark = "#45475a"; # Surface1
    fg = "#585b70"; # Surface2
    fg_light = "#6c7086"; # Overlay0

    # Accent colors (Catppuccin Mocha palette)
    red = "#f38ba8"; # Red
    red_dim = "#eba0ac"; # Maroon

    green = "#a6e3a1"; # Green
    green_dim = "#94e2d5"; # Teal (closest muted green)

    yellow = "#f9e2af"; # Yellow
    yellow_dim = "#f9e2af"; # Yellow (no dim variant in Catppuccin)

    blue = "#89b4fa"; # Blue
    blue_dim = "#74c7ec"; # Sapphire

    purple = "#cba6f7"; # Mauve
    purple_dim = "#b4befe"; # Lavender

    aqua = "#94e2d5"; # Teal
    aqua_dim = "#89dceb"; # Sky

    orange = "#fab387"; # Peach
    orange_dim = "#fab387"; # Peach (no dim variant)

    gray = "#9399b2"; # Overlay2
    gray_dim = "#7f849c"; # Overlay1
  };

  # Keyboard layout (XKB)
  keyboard = {
    layout = "us,ara";
    variant = ",qwerty";
    options = "grp:caps_toggle,grp_led:caps";
  };
}
