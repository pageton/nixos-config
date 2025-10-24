# Lazygit (Git TUI) configuration.
# This module configures lazygit, a terminal UI for git commands

{
  programs.lazygit = {
    enable = true; # Enable lazygit for terminal git operations

    settings = {
      gui.showIcons = true; # Show icons in the interface

      gui.theme = {
        lightTheme = false; # Use dark theme

        # Color scheme for UI elements
        activeBorderColor = [
          "green"
          "bold"
        ]; # Active border color with bold styling

        inactiveBorderColor = [ "grey" ]; # Inactive border color
        selectedLineBgColor = [ "blue" ]; # Selected line background
      };
    };
  };
}
