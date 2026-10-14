# Shell integration and Nix development tools.
{ pkgs, ... }:

{
  programs = {
    bash.enable = true;
    nix-your-shell.enable = true;
  };

  home.packages = with pkgs; [
    nixfmt
    statix
    deadnix
    nixd
    nix-tree
    nix-output-monitor
    cachix
    nix-init
    nurl
  ];
}
