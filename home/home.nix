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

  stylix.targets.zen-browser = {
    enable = true;
    profileNames = [ "default" ];
  };

  programs.home-manager.enable = true;
}
