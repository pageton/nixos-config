# Nix package manager configuration (flakes, GC, etc.).

{ inputs, ... }:

{
  nix = {
    nixPath = [
      "nixpkgs=${inputs.nixpkgs}"
    ];

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
