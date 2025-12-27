# Alacritty terminal emulator configuration.
# This module configures Alacritty, a fast, cross-platform, OpenGL terminal emulator
{lib, ...}: {
  # Enable Alacritty terminal emulator
  programs.alacritty = {
    enable = true;

    settings = {
      # Window configuration
      window = {
        opacity = lib.mkForce 0.95; # Slight transparency for modern look
        blur = true; # Enable background blur
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

        size = lib.mkForce 12.5;

        offset = {
          x = 0;
          y = 1; # Slight vertical offset for better readability
        };
      };

      colors = lib.mkForce {
        primary = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
          dim_foreground = "#7f849c";
          bright_foreground = "#cdd6f4";
        };

        cursor = {
          text = "#1e1e2e";
          cursor = "#f5e0dc";
        };

        vi_mode_cursor = {
          text = "#1e1e2e";
          cursor = "#b4befe";
        };

        search = {
          matches = {
            foreground = "#1e1e2e";
            background = "#d79921";
          };
          focused_match = {
            foreground = "#1e1e2e";
            background = "#a6e3a1";
          };
        };

        hints = {
          start = {
            foreground = "#1e1e2e";
            background = "#d79921";
          };
          end = {
            foreground = "#1e1e2e";
            background = "#fe8019";
          };
        };

        selection = {
          text = "#1e1e2e";
          background = "#f5e0dc";
        };

        normal = {
          black = "#45475a";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#bac2de";
        };

        bright = {
          black = "#585b70";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#a6adc8";
        };
      };

      # Scrolling
      scrolling = {
        history = 50000; # Increased from default 10k
        multiplier = 3; # Scroll speed
      };

      # Selection
      selection = {
        semantic_escape_chars = ",│`|:\"' ()[]{}<>\t";
        save_to_clipboard = true;
      };

      # Cursor
      cursor = {
        style = {
          shape = "Block";
          blinking = "On";
        };
        blink_interval = 750;
        unfocused_hollow = true;
        thickness = 0.15;
      };

      # Live config reload (updated syntax)
      general.live_config_reload = true;

      # Terminal shell configuration
      terminal.shell = {
        program = "zsh";
        args = ["-l"];
      };

      # Working directory
      working_directory = "None";

      # Mouse
      mouse = {
        hide_when_typing = true;
        bindings = [
          {
            mouse = "Right";
            action = "PasteSelection";
          }
        ];
      };

      # Hints (URL/path detection) - simplified to avoid TOML escaping issues
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

      # Debug
      debug = {
        render_timer = false;
        persistent_logging = false;
        log_level = "Warn";
        print_events = false;
      };
    };
  };
}
