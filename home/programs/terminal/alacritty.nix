# Alacritty terminal emulator.
{ constants, lib, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = lib.mkForce 0.95;
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

      scrolling = {
        history = 50000;
        multiplier = 1;
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
    };
  };
}
