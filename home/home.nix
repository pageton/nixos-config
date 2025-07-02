{
  homeStateVersion,
  user,
  pkgs,
  pkgsStable,
  ...
}:

{
  imports = [
    ./system
    ./programs
    ./scripts
    ./secrets
    ../themes/catppuccin.nix
  ];

  disabledModules = [ "programs/hyprpanel" ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = homeStateVersion;
  };

  nixpkgs.config.allowUnfree = true;

  home.packages =
    let
      extraPkgs = import ./packages { inherit pkgs pkgsStable; };
    in
    (with pkgs; [
      nixfmt-rfc-style
      nixd
    ])
    ++ extraPkgs;

  home.file.".face.icon" = {
    source = ./profile_picture.png;
  };

  programs.home-manager.enable = true;
}
