# Home-Manager entry point — imports all sub-modules.
# Actual packages are set by core.nix via home.packages.
{ ... }:
{
  imports = [
    ./core
    ./programs
    ./scripts
    ./desktop
    ./themes
  ];
}
