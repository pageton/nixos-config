{
  homeStateVersion,
  user,
  pkgs,
  pkgsStable,
  inputs,
  ...
}:
{
  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = homeStateVersion;
  };

  nixpkgs.config.allowUnfree = true;

  home.packages =
    let
      Pkgs = import ../packages { inherit pkgs pkgsStable; };
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
