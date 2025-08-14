# Local system packages for the 'pc' host.

{ pkgs, pkgsStable, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim
    showmethekey
  ];
}
