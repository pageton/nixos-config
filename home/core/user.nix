{
  homeStateVersion,
  user,
  pkgs,
  pkgsStable,
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
    # nodejs-slim-20.20.2: permitted because <add reason here>
    permittedInsecurePackages = [ "nodejs-slim-20.20.2" ];
  };

  home.packages = import ../packages { inherit pkgs pkgsStable constants; };

  home.file.".face" = {
    source = ../assets/profile_picture.png;
  };

  fonts.fontconfig.enable = true;
  programs.home-manager.enable = true;
}
