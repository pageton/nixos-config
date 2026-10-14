# Alacritty terminal emulator — primary terminal since Ghostty removal.
# Multiplexing (splits, tabs, sessions) is Zellij's job; Alacritty stays a fast
# single surface with strong selection, hinting, and true-color support.
{ constants, lib, ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
      # Pick up `nix fmt`/manual edits to the generated TOML without a rebuild.
      general.live_config_reload = true;

      env = {
        # 24-bit color; the restored tmux config already enables RGB for
        # `alacritty*` terminals via terminal-features.
        TERM = "alacritty";
      };

      window = {
        opacity = lib.mkForce 1.0;
        padding = {
          x = 8;
          y = 8;
        };
        dynamic_padding = true;
        decorations = "None";
        startup_mode = "Windowed";
      };

      font = {
        normal = {
          family = lib.mkForce constants.font.monoNerd;
          style = "Regular";
        };
        bold = {
          family = lib.mkForce constants.font.monoNerd;
          style = "Bold";
        };
        italic = {
          family = lib.mkForce constants.font.monoNerd;
          style = "Italic";
        };
        size = lib.mkForce constants.font.size;
        offset.y = 1;
      };

      # Explicit cursor colors, mirroring the removed Ghostty settings.
      # mkForce beats the Stylix target so the yellow cursor survives retheming.
      colors.cursor = lib.mkForce {
        text = constants.color.bg_hard;
        cursor = constants.color.yellow;
      };

      scrolling = {
        history = 100000;
        multiplier = 5;
      };

      selection = {
        semantic_escape_chars = ",│`|:\"' ()[]{}<>\t";
        save_to_clipboard = true;
      };

      cursor = {
        style = {
          shape = "Block";
          blinking = "On";
        };
        blink_interval = 750;
        unfocused_hollow = true;
      };

      mouse.hide_when_typing = true;

      # URL hints replace Ghostty's link handling: Ctrl+Shift+U (or hover with
      # the modifiers) opens the URL under the cursor via xdg-open.
      hints = {
        enabled = [
          {
            regex = "(ipfs:|ipns:|magnet:|mailto:|gemini:|gopher:|https:|http:|news:|file:|git:|ssh:|ftp:)[^\\u0000-\\u001F\\u007F-\\u009F<>\"\\\\s{-}^\\u007F]+";
            command = "xdg-open";
            post_processing = true;
            mouse = {
              enabled = true;
              mods = "None";
            };
            binding = {
              key = "U";
              mods = "Control|Shift";
            };
          }
        ];
      };

      keyboard.bindings = [
        # Mirror the removed Ghostty keybinds. Font-size zoom and
        # Ctrl+Shift+C/V copy-paste are Alacritty defaults already.
        {
          key = "N";
          mods = "Control|Shift";
          action = "CreateNewWindow";
        }
      ];
    };
  };
}
