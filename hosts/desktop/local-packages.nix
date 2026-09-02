# Local system packages for the 'desktop' host.

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    showmethekey
    fontconfig
  ];
}
