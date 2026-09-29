# Browser dependencies for Chrome/Chromium-based applications (Puppeteer etc.).
# Most libraries are provided by nix-ld.nix; this covers packages + env.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Chromium directly for testing and fallback
    chromium

    # Virtual display for headful mode (useful for debugging and screenshots)
    xvfb-run
    xauth
  ];

  environment.variables = {
    CHROME_DEVEL_SANDBOX = "${pkgs.chromium}/bin/chrome-devel-sandbox";
    PUPPETEER_HEADLESS = "new";
  };
}
