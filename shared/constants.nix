# Shared constants used across NixOS and Home Manager configurations.
# Single source of truth for terminal, editor, font, theme, and keyboard settings.
#
# Usage (in NixOS modules):
#   { constants, ... }:
#   { TERMINAL = constants.terminal; }
#
# Usage (in Home Manager modules):
#   { constants, ... }:
#   { config.programs.alacritty.settings.font.normal.family = constants.font.mono; }
{
  # User Identity (Git, GitHub, Contact)
  user = {
    handle = "Sadiq";
    name = "Sadiq";
    email = "pageton@proton.me";
    githubEmail = "pageton@proton.me";
    signingKey = "5684AD6E4045F283";
  };

  # Terminal emulator
  terminal = "alacritty";
  terminalAppId = "Alacritty";

  # Default text editor
  editor = "nvim";
  editorAppId = "nvim|Nvim|neovide|org\.neovide\.Neovide";

  # Fonts
  font = {
    mono = "JetBrains Mono Nerd Font";
    size = 13;
  };

  # Theme (Kanagawa Wave)
  theme = "kanagawa-wave";

  # Kanagawa Wave color palette
  # Mapped to the same semantic structure for compatibility with ai-agents and other modules.
  # Palette reference: https://github.com/rebelot/kanagawa.nvim
  color = {
    # Background shades (Kanagawa Wave ink colors)
    bg_hard = "#16161D"; # sumiInk0 — darkest background
    bg = "#1F1F28"; # sumiInk1 — main background
    bg_soft = "#2A2A37"; # sumiInk2 — slightly lighter
    bg0 = "#363646"; # sumiInk3 — surface
    bg1 = "#54546D"; # sumiInk4 — elevated surface
    # Foreground shades
    fg0 = "#DCD7BA"; # fujiWhite — primary foreground
    fg_dark = "#54546D"; # sumiInk4
    fg = "#727169"; # fujiGray
    fg_light = "#C8C093"; # oldWhite

    # Accent colors (Kanagawa Wave palette)
    red = "#C34043"; # autumnRed
    red_dim = "#E46876"; # waveRed

    green = "#76946A"; # autumnGreen
    green_dim = "#98BB6C"; # springGreen

    yellow = "#C0A36E"; # boatYellow2
    yellow_dim = "#E6C384"; # carpYellow

    blue = "#7E9CD8"; # crystalBlue
    blue_dim = "#7FB4CA"; # springBlue

    purple = "#957FB8"; # oniViolet
    purple_dim = "#938AA9"; # springViolet1

    aqua = "#6A9589"; # waveAqua1
    aqua_dim = "#7AA89F"; # waveAqua2

    orange = "#FFA066"; # surimiOrange
    orange_dim = "#DCA561"; # autumnYellow

    gray = "#727169"; # fujiGray
    gray_dim = "#54546D"; # sumiInk4
  };

  # Keyboard layout (XKB)
  keyboard = {
    layout = "us,ara";
    variant = ",qwerty";
    options = "grp:caps_toggle,grp_led:caps";
  };

  # External service API endpoints.
  services = {
    zai = {
      apiRoot = "https://api.z.ai/api"; # Z.AI API root (Anthropic-compatible + MCP)
    };
  };
}
