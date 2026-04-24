# Browser isolation with multiple profiles for different contexts.
# Provides isolated browser profiles for work, personal, and Tor browsing.
#
# Tor browser scripts share common logic extracted into `let` bindings:
#   - torCheckPort:    detects running Tor SOCKS proxy (port 9150 or 9050)
#   - torUserJs:       Firefox/Zen Browser preferences for Tor proxy hardening
#   - torLaunchZen:    launches Zen Browser with a given profile directory
{ inputs, pkgs, ... }:
let
  zenBin = "${inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta}/bin/zen-beta";
  mkPersistentProfile = profileName: ''
    PROFILE_DIR="$HOME/${profileName}"
    mkdir -p "$PROFILE_DIR"
    chmod 700 "$PROFILE_DIR"
  '';

  # Detect running Tor SOCKS proxy. Sets TOR_PORT and exits with error if none found.
  torCheckPort = ''
    check_port() {
      local host=$1
      local port=$2
      timeout 1 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null
    }

    TOR_PORT=""
    if check_port 127.0.0.1 9150; then
      TOR_PORT="9150"  # Tor Browser's port
    elif check_port 127.0.0.1 9050; then
      TOR_PORT="9050"  # System Tor port
    else
      echo "Error: Tor SOCKS proxy not found on ports 9050 or 9150" >&2
      echo "" >&2
      echo "Please start Tor Browser or enable the Tor service:" >&2
      echo "  sudo systemctl enable --now tor.service" >&2
      echo "" >&2
      echo "Then try again." >&2
      exit 1
    fi
  '';

  # Shared Firefox/Zen Browser preferences for Tor proxy hardening.
  # $TOR_PORT must be set before the heredoc is expanded.
  torUserJs = ''
    // Tor SOCKS5 Proxy Configuration
    user_pref("network.proxy.type", 1);
    user_pref("network.proxy.socks", "127.0.0.1");
    user_pref("network.proxy.socks_port", $TOR_PORT);
    user_pref("network.proxy.socks_remote_dns", true);
    user_pref("network.proxy.socks_version", 5);

    // DNS Leak Prevention
    user_pref("network.dns.blockDotOnion", false);
    user_pref("network.http.sendRefererHeader", 0);
    user_pref("privacy.firstparty.isolate", true);
    user_pref("network.dns.disablePrefetch", true);
    user_pref("network.dns.disableIPv6", true);
    user_pref("network.http.speculative-parallel-limit", 0);
    user_pref("network.predictor.enabled", false);

    // Complete WebRTC Block
    user_pref("media.peerconnection.enabled", false);
    user_pref("media.peerconnection.ice.default_address_only", true);
    user_pref("media.peerconnection.ice.no_host", true);
    user_pref("media.peerconnection.ice.proxy_only", true);
    user_pref("media.navigator.enabled", false);
    user_pref("webgl.disabled", true);
    user_pref("dom.ipc.plugins.enabled", false);

    // Disable safe browsing (privacy leak to Google)
    user_pref("browser.safebrowsing.downloads.enabled", false);
    user_pref("browser.safebrowsing.malware.enabled", false);
    user_pref("extensions.blocklist.enabled", true);
  '';

  # Launch Zen Browser with Tor proxy settings. Expects PROFILE_DIR to be set.
  torLaunchZen = ''
    echo "Routing Zen Browser through Tor SOCKS proxy (127.0.0.1:$TOR_PORT)..."

    cat > "$PROFILE_DIR/user.js" <<EOF
    ${torUserJs}
    EOF

    exec ${zenBin} --profile "$PROFILE_DIR" --new-instance 2>/dev/null
  '';
in
{
  home.file = {
    ".local/bin/browser-work" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Work browser profile - isolated from personal browsing
        set -euo pipefail

        ${mkPersistentProfile ".zen-work"}

        exec ${zenBin} --profile "$PROFILE_DIR" --new-instance 2>/dev/null
      '';
    };

    ".local/bin/browser-work-tor" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Zen Browser routed through Tor SOCKS proxy with persistent profile
        set -euo pipefail

        ${mkPersistentProfile ".zen-work-tor"}

        ${torCheckPort}

        ${torLaunchZen}
      '';
    };

    ".local/bin/browser-tmp-tor" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Temporary Tor browser - profile deleted on exit
        set -euo pipefail

        PROFILE_DIR="$(mktemp -d)"
        echo "Starting ephemeral Tor browser with profile: $PROFILE_DIR"
        echo "Profile will be deleted on exit"

        ${torCheckPort}

        trap "rm -rf '$PROFILE_DIR'" EXIT

        ${torLaunchZen}
      '';
    };

    # Desktop files for wofi integration
    ".local/share/applications/browser-work.desktop" = {
      text = ''
        [Desktop Entry]
        Name=Browser (Work)
        Exec=browser-work
        Type=Application
        Icon=zen-browser
        Categories=Network;WebBrowser;
      '';
    };

    ".local/share/applications/browser-work-tor.desktop" = {
      text = ''
        [Desktop Entry]
        Name=Browser (Work + Tor)
        Exec=browser-work-tor
        Type=Application
        Icon=zen-browser
        Categories=Network;WebBrowser;
      '';
    };

    ".local/share/applications/browser-tmp-tor.desktop" = {
      text = ''
        [Desktop Entry]
        Name=Browser (Temporary + Tor)
        Exec=browser-tmp-tor
        Type=Application
        Icon=zen-browser
        Categories=Network;WebBrowser;
      '';
    };
  };
}
