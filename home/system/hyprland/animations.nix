{config, ...}: let
  animationSpeed = config.theme.animation-speed;

  animationDuration =
    if animationSpeed == "slow"
    then "4"
    else if animationSpeed == "medium"
    then "2.5"
    else "1.5";
  borderDuration =
    if animationSpeed == "slow"
    then "10"
    else if animationSpeed == "medium"
    then "6"
    else "3";
in {
  wayland.windowManager.hyprland.settings = {
    animations = {
      enabled = true;
      bezier = [
        "fluent_decel, 0, 0.2, 0.4, 1" # Fluent deceleration curve
        "easeOutCirc, 0, 0.55, 0.45, 1" # Circular easing out
        "easeOutExpo, 0.16, 1, 0.3, 1" # Exponential easing out
        "softAcDecel, 0.26, 0.26, 0.15, 1" # Soft acceleration/deceleration
      ];

      animation = [
        "windows, 1, ${animationDuration}, fluent_decel, slide" # Window open/close
        "windowsOut, 1, ${animationDuration}, fluent_decel, slide" # Window close
        "windowsMove, 1, 2, softAcDecel" # Window movement
        "workspaces, 0, 0, fluent_decel" # Workspace switching
        "specialWorkspace, 1, ${animationDuration}, fluent_decel, slidevert" # Special workspace
        "layers, 1, ${animationDuration}, easeOutCirc" # Layer transitions
        "layersIn, 1, ${animationDuration}, easeOutCirc, left" # Layer in animation
        "layersOut, 1, ${animationDuration}, fluent_decel, right" # Layer out animation
        "fade, 1, ${animationDuration}, fluent_decel" # Fade transitions
        "border, 1, ${borderDuration}, easeOutCirc" # Border animations
      ];
    };
  };
}
