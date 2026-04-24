# Idle management (swayidle).
# Chain: 3min dim -> 8min lock (Noctalia) -> 20min DPMS off.
{ config, pkgs, ... }:
let
  lockCmd = "${config.home.profileDirectory}/bin/noctalia-shell ipc call lockScreen lock";
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
    ];

    events = {
      before-sleep = lockCmd;
      lock = "${pkgs.cliphist}/bin/cliphist wipe && ${lockCmd}";
    };
  };
}
