{
  homeStateVersion,
  user,
  pkgs,
  pkgsStable,
  inputs,
  constants,
  ...
}:
{
  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = homeStateVersion;
  };

  nixpkgs.config = {
    allowUnfree = true; # needed by HM — flake-level nixpkgsConfig does NOT propagate to HM's nixpkgs.config
    permittedInsecurePackages = [ "nodejs-slim-20.20.2" ];
  };

  home.packages =
    let
      Pkgs = import ../packages { inherit pkgs pkgsStable constants; };
    in
    Pkgs
    ++ [
      inputs.ghgrab.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.zellij-tui.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

  home.file.".face" = {
    source = ../assets/profile_picture.png;
  };

  fonts.fontconfig.enable = true;
  programs.home-manager.enable = true;
}
