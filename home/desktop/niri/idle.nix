# Idle management (swayidle).
# Chain: 3min dim -> 8min lock (Noctalia v5) -> 20min DPMS off -> 30min suspend.
#
# NOTE: clipboard history is intentionally NEVER cleared. The previous config
# ran `cliphist wipe` on every screen lock (an OPSEC measure), but the user
# wants persistent clipboard history — pins/history survive across locks.
{ config, pkgs, ... }:
let
  lockCmd = "${config.home.profileDirectory}/bin/noctalia msg session lock";
in
{
  services.swayidle = {
    enable = true;

    timeouts = [
      {
        timeout = 180;
        command = "${pkgs.brightnessctl}/bin/brightnessctl -s set 30";
        resumeCommand = "${pkgs.brightnessctl}/bin/brightnessctl -r";
      }
      {
        timeout = 480;
        command = lockCmd;
      }
      {
        timeout = 1200;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      }
      {
        timeout = 1800;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];

    events = {
      before-sleep = lockCmd;
      lock = lockCmd;
    };
  };
}
