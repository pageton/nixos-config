# Imports all NixOS modules.
{
  imports = [
    ./core
    ./hardware
    ./desktop
    ./network
    ./security-stack
    ./apps
    ./virtualization
    ./observability
    ./performance
    ./maintenance
  ];
}
