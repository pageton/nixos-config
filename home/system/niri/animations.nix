# Theme-driven animation configuration for niri.
{config, ...}: let
  animationSpeed = config.theme.animation-speed;

  # Spring stiffness scales with animation speed
  springStiffness =
    if animationSpeed == "fast"
    then 1200
    else if animationSpeed == "medium"
    then 800
    else 400;

  # Easing durations in ms
  openDuration =
    if animationSpeed == "fast"
    then 100
    else if animationSpeed == "medium"
    then 200
    else 300;

  closeDuration =
    if animationSpeed == "fast"
    then 80
    else if animationSpeed == "medium"
    then 150
    else 250;
in {
  programs.niri.settings.animations = {
    workspace-switch.kind.spring = {
      damping-ratio = 1.0;
      stiffness = springStiffness + 200;
      epsilon = 0.0001;
    };

    horizontal-view-movement.kind.spring = {
      damping-ratio = 1.0;
      stiffness = springStiffness;
      epsilon = 0.0001;
    };

    window-open.kind.easing = {
      duration-ms = openDuration;
      curve = "ease-out-expo";
    };

    window-close.kind.easing = {
      duration-ms = closeDuration;
      curve = "ease-out-quad";
    };

    window-movement.kind.spring = {
      damping-ratio = 1.0;
      stiffness = springStiffness;
      epsilon = 0.0001;
    };

    window-resize.kind.spring = {
      damping-ratio = 1.0;
      stiffness = springStiffness;
      epsilon = 0.0001;
    };

    config-notification-open-close.kind.spring = {
      damping-ratio = 0.6;
      stiffness = springStiffness + 200;
      epsilon = 0.0001;
    };

    overview-open-close.kind.spring = {
      damping-ratio = 1.0;
      stiffness = springStiffness;
      epsilon = 0.0001;
    };
  };
}
