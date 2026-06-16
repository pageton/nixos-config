# Browser dependencies for Chrome/Chromium-based applications.
# This module provides system libraries and environment settings needed for
# Puppeteer and other Chrome-based tools. Note: Most libraries are provided by
# the nix-ld module, this focuses on environment configuration.
{ pkgs, ... }: {
  config = {
    # Add browser-related packages to system
    environment.systemPackages = with pkgs; [
      # Install Chromium directly for testing and fallback
      chromium

      # Virtual display for headful mode (useful for debugging and screenshots)
      xvfb-run
      xauth
    ];

    # Set environment variables for Chrome and Puppeteer
    environment.variables = {
      CHROME_DEVEL_SANDBOX = "${pkgs.chromium}/bin/chrome-devel-sandbox";
      PUPPETEER_HEADLESS = "new";
    };
  };
}
