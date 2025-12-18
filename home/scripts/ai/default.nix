{ pkgs, ... }:

let
  # Import all the script modules
  askScript = pkgs.callPackage ./ask.nix { };
  commitScript = pkgs.callPackage ./commit.nix { };
  helpScript = pkgs.callPackage ./help.nix { };
in
{
  # Add all AI scripts to home.packages
  home.packages = [
    askScript
    commitScript
    helpScript
  ];
}