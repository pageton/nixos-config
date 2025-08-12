# Power management configuration

{ lib, ... }:

{
  powerManagement.enable = true;
  programs.gamemode.enable = false;

  services = {
    power-profiles-daemon.enable = false;
    throttled.enable = lib.mkDefault true;
  };
}
