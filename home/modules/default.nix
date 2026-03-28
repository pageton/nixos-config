{ ... }:
{
  imports = [
    ./core.nix
    ./session.nix
    ./desktop-entries.nix
    ./gtk-dconf.nix
    ./activation.nix
  ];
}
