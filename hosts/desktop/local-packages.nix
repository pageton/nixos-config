# Local system packages for the 'desktop' host.

{ pkgs, pkgsStable, ... }:

{
  environment.systemPackages = with pkgs; [
    showmethekey
    fontconfig
  ];
}
