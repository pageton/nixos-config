{
  lib,
  hostname,
  pkgs,
  ...
}: let
  windowSwitcher = pkgs.writeScriptBin "window-switcher" ''
    #!/bin/sh
    # Get list of all windows with workspace, class, and title information
    windows=$(hyprctl clients -j | jq -r '.[] | "\(.workspace.id):\(.workspace.name) - \(.class) - \(.title)"')
    selected=$(echo "$windows" | wofi --dmenu --prompt "Switch to window" --width 800)

    if [[ -n "$selected" ]]; then
      # Find the window address and focus it
      address=$(hyprctl clients -j | jq -r --arg sel "$selected" '.[] | select("\(.workspace.id):\(.workspace.name) - \(.class) - \(.title)" == $sel) | .address')
      hyprctl dispatch focuswindow "address:$address"
    fi
  '';

  menu = pkgs.writeShellScriptBin "menu" ''
    if pgrep wofi; then
    	pkill wofi
    else
    	wofi -p " Apps" --show drun &
    fi
  '';

  powermenu = pkgs.writeShellScriptBin "powermenu" ''
    if pgrep wofi; then
    	pkill wofi
    else
      options=(
        "󰌾 Lock"
        "󰍃 Logout"
        " Suspend"
        "󰑐 Reboot"
        "󰿅 Shutdown"
      )

      selected=$(printf '%s\n' "''${options[@]}" | wofi -p " Powermenu" --dmenu)
      selected=''${selected:2}

      case $selected in
        "Lock")
          ${pkgs.hyprlock}/bin/hyprlock
          ;;
        "Logout")
          hyprctl dispatch exit
          ;;
        "Suspend")
          systemctl suspend
          ;;
        "Reboot")
          systemctl reboot
          ;;
        "Shutdown")
          systemctl poweroff
          ;;
      esac
    fi
  '';

  quickmenu = pkgs.writeShellScriptBin "quickmenu" ''
    if pgrep wofi; then
    	pkill wofi
    else
      options=(
        "󰅶 Caffeine"
        "󰖔 Night-shift"
        "󰈊 Hyprpicker"
        "󰖂 Toggle VPN"
      )

      selected=$(printf '%s\n' "''${options[@]}" | wofi -p " Quickmenu" --dmenu)
      selected=''${selected:2}

      case $selected in
        "Caffeine")
          caffeine
          ;;
        "Night-shift")
          night-shift
          ;;
        "Hyprpicker")
          sleep 0.2 && ${pkgs.hyprpicker}/bin/hyprpicker -a
          ;;
        "Toggle VPN")
          openvpn-toggle
          ;;
      esac
    fi
  '';

  lock = pkgs.writeShellScriptBin "lock" ''
    ${pkgs.hyprlock}/bin/hyprlock
  '';

  clipboard = pkgs.writeShellScriptBin "clipboard" ''
    if pgrep wofi; then
      pkill wofi
    else
      cliphist list | wofi --dmenu --prompt "Clipboard" | cliphist decode | wl-copy
    fi
  '';
in {
  home.packages = lib.mkIf (hostname != "server") [
    menu
    powermenu
    lock
    quickmenu
    windowSwitcher
    clipboard
  ];
}
