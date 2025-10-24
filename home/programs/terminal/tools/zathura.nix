# Zathura PDF viewer configuration.

{
  programs.zathura = {
    enable = true; # Enable zathura document viewer

    # Custom key mappings for better navigation
    mappings = {
      D = "toggle_page_mode"; # Toggle between single/multi-page view
      d = "scroll half_down"; # Scroll down by half page
      u = "scroll half_up"; # Scroll up by half page
    };

    # Viewer options and appearance
    options = {
      font = "JetBrains Mono Bold 13"; # Font for UI elements
    };
  };
}
