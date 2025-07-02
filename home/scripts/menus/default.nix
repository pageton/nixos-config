{ pkgs, ... }:

let
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

in
{
  home.packages = [
    menu
    powermenu
    lock
    quickmenu
  ];
}
