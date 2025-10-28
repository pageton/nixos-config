# Ghostty terminal emulator configuration.
# This module configures Ghostty, a fast, cross-platform, OpenGL terminal emulator
{
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-style-bold = "bold";
      font-size = 13;
      shell-integration-features = "no-cursor";
      cursor-style = "block";
      mouse-hide-while-typing = true;
      background-opacity = 0.8;
      quick-terminal-position = "center";
      quick-terminal-screen = "mouse";
      quick-terminal-size = "50%, 50%";
      gtk-quick-terminal-layer = "top";
      quick-terminal-keyboard-interactivity = "exclusive";
      quick-terminal-autohide = true;
      keybind = [ "global:super+tab=toggle_quick_terminal" ];
    };
  };
}
