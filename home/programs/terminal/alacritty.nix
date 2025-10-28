# Alacritty terminal emulator configuration.
# This module configures Alacritty, a fast, cross-platform, OpenGL terminal emulator

{ lib, ... }:

{
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

        size = lib.mkForce 13.0;

        offset = {
          x = 0;
          y = 1; # Slight vertical offset for better readability
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
        args = [ "-l" ];
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
