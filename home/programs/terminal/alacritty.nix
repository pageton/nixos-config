# Alacritty terminal emulator — Kanagawa themed via Stylix base16.
{
  config,
  lib,
  ...
}: let
  inherit (config.lib.stylix) colors;
  fontSize = config.stylix.fonts.sizes.terminal;
in {
  programs.alacritty = {
    enable = true;

    settings = {
      # ── Window ───────────────────────────────────────────────────
      window = {
        opacity = lib.mkForce 0.95;
        blur = true;
        padding = {
          x = 8;
          y = 8;
        };
        dynamic_padding = true;
        decorations = "full";
        startup_mode = "Windowed";
        title = "Alacritty";
        class = {
          instance = "Alacritty";
          general = "Alacritty";
        };
      };

      # ── Font ─────────────────────────────────────────────────────
      font = {
        builtin_box_drawing = true;

        normal = {
          family = lib.mkForce "JetBrainsMono Nerd Font";
          style = lib.mkForce "Bold";
        };

        bold = {
          family = "JetBrains Mono";
          style = "ExtraBold";
        };

        italic = {
          family = "JetBrains Mono";
          style = "Italic";
        };

        bold_italic = {
          family = "JetBrains Mono";
          style = "BoldItalic";
        };

        size = lib.mkForce (fontSize * 1.0);

        offset = {
          x = 0;
          y = 1;
        };
      };

      # ── Colors (Kanagawa Wave) ───────────────────────────────────
      colors = lib.mkForce {
        primary = {
          background = "#${colors.base00}"; # sumiInk1
          foreground = "#${colors.base05}"; # fujiWhite
          dim_foreground = "#${colors.base04}"; # oldWhite
          bright_foreground = "#${colors.base05}"; # fujiWhite
        };

        cursor = {
          text = "#${colors.base00}"; # sumiInk1
          cursor = "#${colors.base0A}"; # boatYellow2
        };

        vi_mode_cursor = {
          text = "#${colors.base00}"; # sumiInk1
          cursor = "#${colors.base0D}"; # crystalBlue
        };

        search = {
          matches = {
            foreground = "#${colors.base00}"; # sumiInk1
            background = "#${colors.base0A}"; # boatYellow2
          };
          focused_match = {
            foreground = "#${colors.base00}"; # sumiInk1
            background = "#${colors.base0B}"; # autumnGreen
          };
        };

        hints = {
          start = {
            foreground = "#${colors.base00}"; # sumiInk1
            background = "#${colors.base0A}"; # boatYellow2
          };
          end = {
            foreground = "#${colors.base00}"; # sumiInk1
            background = "#${colors.base09}"; # surimiOrange
          };
        };

        selection = {
          text = "#${colors.base05}"; # fujiWhite
          background = "#${colors.base02}"; # winterBlue
        };

        normal = {
          black = "#${colors.base01}"; # sumiInk0
          red = "#${colors.base08}"; # autumnRed
          green = "#${colors.base0B}"; # autumnGreen
          yellow = "#${colors.base0A}"; # boatYellow2
          blue = "#${colors.base0D}"; # crystalBlue
          magenta = "#${colors.base0E}"; # oniViolet
          cyan = "#${colors.base0C}"; # waveAqua1
          white = "#${colors.base05}"; # fujiWhite
        };

        bright = {
          black = "#${colors.base03}"; # sumiInk6
          red = "#${colors.base08}"; # autumnRed
          green = "#${colors.base0B}"; # autumnGreen
          yellow = "#${colors.base0A}"; # boatYellow2
          blue = "#${colors.base0D}"; # crystalBlue
          magenta = "#${colors.base0E}"; # oniViolet
          cyan = "#${colors.base0C}"; # waveAqua1
          white = "#${colors.base06}"; # oldWhite lighter
        };
      };

      # ── Scrolling ────────────────────────────────────────────────
      scrolling = {
        history = 50000;
        multiplier = 3;
      };

      # ── Selection ────────────────────────────────────────────────
      selection = {
        semantic_escape_chars = ",│`|:\"' ()[]{}<>\t";
        save_to_clipboard = true;
      };

      # ── Cursor ───────────────────────────────────────────────────
      cursor = {
        style = {
          shape = "Block";
          blinking = "On";
        };
        blink_interval = 750;
        unfocused_hollow = true;
        thickness = 0.15;
      };

      # ── General ──────────────────────────────────────────────────
      general.live_config_reload = true;

      terminal.shell = {
        program = "zsh";
        args = ["-l"];
      };

      working_directory = "None";

      # ── Mouse ────────────────────────────────────────────────────
      mouse = {
        hide_when_typing = true;
        bindings = [
          {
            mouse = "Right";
            action = "PasteSelection";
          }
        ];
      };

      # ── Hints (URL detection) ───────────────────────────────────
      hints = {
        enabled = [
          {
            regex = "https?://[a-zA-Z0-9._~:/?#@!$&'()*+,;=-]+";
            hyperlinks = true;
            post_processing = true;
            persist = false;
            action = "Copy";
            binding = {
              key = "U";
              mods = "Control|Shift";
            };
            mouse = {
              enabled = true;
              mods = "None";
            };
          }
        ];
      };

      # ── Debug ────────────────────────────────────────────────────
      debug = {
        render_timer = false;
        persistent_logging = false;
        log_level = "Warn";
        print_events = false;
      };
    };
  };
}
