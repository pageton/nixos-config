{ pkgs, ... }:

let
  # Import all build script modules
  modulesCheckScript = pkgs.callPackage ./modules-check.nix { };
in
{
  # Add build scripts to home.packages
  home.packages = [
    modulesCheckScript
  ];
}