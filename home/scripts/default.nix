# Home-Manager user scripts — build helpers and utilities.
{ ... }:
{
  imports = [
    ./build # Build and deployment helper scripts
    ./nerdfont-fzf.nix # Nerd Font icon integration for fzf
  ];
}
