# Shared constants used across NixOS and Home Manager configurations.
# Single source of truth for terminal, editor, font, theme, and keyboard settings.
#
# Usage (in NixOS modules):
#   { constants, ... }:
#   { TERMINAL = constants.terminal; }
#
# Usage (in Home Manager modules):
#   { constants, ... }:
#   { config.programs.alacritty.settings.font.normal.family = constants.font.monoNerd; }
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
  terminalAppId = "org.alacritty.Alacritty"; # Wayland app-id — used in window rules and dock

  # Default text editor
  editor = "nvim";
  editorAppId = "nvim|Nvim|neovide|org\.neovide\.Neovide";

  # Fonts
  font = {
    mono = "JetBrains Mono";
    monoNerd = "JetBrainsMono Nerd Font";
    size = 13;
    sizeApplications = 11;
  };

  # Theme identifiers (used for reference/fetch tools).
  # Stylix theming and custom modules all use Catppuccin Mocha.
  theme = "catppuccin-mocha";
  palette = "catppuccin-mocha";

  # Catppuccin Mocha color palette
  # Mapped to the same semantic structure for compatibility with ai-agents and other modules.
  # Palette reference: https://github.com/catppuccin/catppuccin
  color = {
    # Background shades
    bg_hard = "#11111B"; # crust — darkest background
    bg = "#1E1E2E"; # base — main background
    bg_soft = "#313244"; # surface0 — slightly lighter
    bg0 = "#45475A"; # surface1 — surface
    bg1 = "#585B70"; # surface2 — elevated surface
    # Foreground shades
    fg0 = "#CDD6F4"; # text — primary foreground
    fg_dark = "#585B70"; # surface2
    fg = "#A6ADC8"; # overlay0
    fg_light = "#BAC2DE"; # subtext1

    # Accent colors (Catppuccin Mocha palette)
    red = "#F38BA8"; # red
    red_dim = "#EBA0AC"; # maroon

    green = "#A6E3A1"; # green
    green_dim = "#94E2D5"; # teal

    yellow = "#F9E2AF"; # yellow
    yellow_dim = "#F5C2E7"; # pink

    blue = "#89B4FA"; # blue
    blue_dim = "#74C7EC"; # sky

    purple = "#CBA6F7"; # mauve
    purple_dim = "#F5C2E7"; # pink

    aqua = "#94E2D5"; # teal
    aqua_dim = "#89DCEB"; # sapphire

    orange = "#FAB387"; # peach
    orange_dim = "#EBA0AC"; # maroon

    gray = "#A6ADC8"; # overlay0
    gray_dim = "#585B70"; # surface2
  };

  # Keyboard layout (XKB)
  keyboard = {
    layout = "us,ara";
    variant = ",qwerty";
    options = "grp:caps_toggle,grp_led:caps";
  };

  # Mullvad SOCKS5 proxy endpoints for browser profiles.
  # Never mix proxies - each profile gets a dedicated exit.
  proxies = {
    brave = {
      personal = "fi-hel-wg-socks5-001.relays.mullvad.net"; # Finland
      work = "de-fra-wg-socks5-001.relays.mullvad.net"; # Germany
      banking = "nl-ams-wg-socks5-001.relays.mullvad.net"; # Netherlands
      shopping = "ro-buh-wg-socks5-001.relays.mullvad.net"; # Romania
      illegal = "ch-zur-wg-socks5-001.relays.mullvad.net"; # Switzerland
    };
    zen-browser = {
      personal = "se-sto-wg-socks5-001.relays.mullvad.net"; # Sweden
      work = "de-fra-wg-socks5-001.relays.mullvad.net"; # Germany
      banking = "nl-ams-wg-socks5-001.relays.mullvad.net"; # Netherlands
      shopping = "ro-buh-wg-socks5-001.relays.mullvad.net"; # Romania
      illegal = "ch-zur-wg-socks5-001.relays.mullvad.net"; # Switzerland
    };
    i2pd = "127.0.0.1"; # Local I2P daemon
  };

  localhost = "127.0.0.1";

  # Service ports — single source of truth for localhost services.
  ports = {
    tor-socks = 9050; # Tor SOCKS5 proxy
    tor-dns = 9053; # Tor DNS port
    socks = 1080; # Default SOCKS5 proxy port
    i2pd-socks = 4447; # I2P SOCKS proxy port
    glance = 8082; # Glance dashboard
    activitywatch = 5600;
    vnc = 5900;
    vnc-web = 6080;
  };

  # Paths relative to HOME for repo-local resources.
  paths = {
    scripts = "System/scripts";
    screens = "Screens";
    opencodeLogDir = ".local/share/opencode/log";
    codexLogDir = ".codex/log";
  };

  # External service API endpoints.
  services = {
    zai = {
      apiRoot = "https://api.z.ai/api"; # Z.AI API root (Anthropic-compatible + MCP)
      timeout = 3000000; # API timeout in ms
      models = {
        haiku = "glm-5-turbo";
        sonnet = "glm-5.1";
        opus = "glm-5.1";
      };
    };
  };
}
