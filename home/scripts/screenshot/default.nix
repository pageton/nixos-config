{pkgsStable, ...}: let
  screenshotScript = pkgsStable.writeScriptBin "smart-screenshot" ''
    #!${pkgsStable.bash}/bin/bash
    # Screenshot using grim+slurp - the standard Wayland tools

    SCREENSHOT_DIR="$HOME/Screens"
    mkdir -p "$SCREENSHOT_DIR"

    # Function to take screenshot
    take_screenshot() {
        local mode="$1"

        case "$mode" in
            "region")
                # Region selection with slurp
                region=$(slurp 2>/dev/null)
                if [[ -n "$region" ]]; then
                    if grim -g "$region" - | wl-copy; then
                        notify-send "Screenshot" "Region saved to clipboard" -t 2000
                    else
                        notify-send "Screenshot" "Failed to capture region" -t 2000
                    fi
                else
                    notify-send "Screenshot" "Region selection cancelled" -t 2000
                fi
                ;;
            "window")
                # Active window
                window_geometry=$(hyprctl activewindow -j 2>/dev/null | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null)
                if [[ -n "$window_geometry" ]] && [[ "$window_geometry" != "null" ]]; then
                    if grim -g "$window_geometry" - | wl-copy; then
                        notify-send "Screenshot" "Window saved to clipboard" -t 2000
                    else
                        notify-send "Screenshot" "Failed to capture window" -t 2000
                    fi
                else
                    notify-send "Screenshot" "Failed to get window geometry" -t 2000
                fi
                ;;
            "active")
                # Active monitor
                monitor=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .name' 2>/dev/null)
                if [[ -n "$monitor" ]] && [[ "$monitor" != "null" ]]; then
                    if grim -o "$monitor" - | wl-copy; then
                        notify-send "Screenshot" "Active screen saved to clipboard" -t 2000
                    else
                        notify-send "Screenshot" "Failed to capture screen" -t 2000
                    fi
                else
                    notify-send "Screenshot" "Failed to get active monitor" -t 2000
                fi
                ;;
            *)
                echo "Usage: smart-screenshot {region|window|active}"
                exit 1
                ;;
        esac
    }

    take_screenshot "$1"
  '';
in {
  nixpkgs.overlays = [
    (final: prev: {
      inherit screenshotScript;
    })
  ];

  home.packages = [
    screenshotScript
  ];
}
