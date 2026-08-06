{ config, ... }:

{
  programs.swaylock = {
    enable = true;

    settings = {
      clock = true;
      timestr = "%I:%M %p";
      font = config.stylix.fonts.monospace.name;
      font-size = 24;
      indicator-idle-visible = false;
      indicator-radius = 100;
      indicator-thickness = 7;
      show-failed-attempts = true;
      ignore-empty-password = true;
    };
  };
}
