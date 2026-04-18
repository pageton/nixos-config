{
  description = "NixOS + Home-Manager flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixcord = {
      url = "github:FlameFlag/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri.url = "github:sodiboo/niri-flake"; # Do NOT follow nixpkgs — mesa compatibility

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-wallpaper = {
      url = "github:lunik1/nix-wallpaper";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghgrab = {
      url = "github:abhixdd/ghgrab/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zellij-tui = {
      url = "github:pageton/zellij-tui";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      # self omitted — not currently needed. Add back as a parameter to access:
      #   self.lastModifiedDate — for version strings
      #   self.outPath          — for embedding repo path
      #   self.rev              — for git revision in prompts
      # Pattern: add `self` to the destructured inputs, then pass
      # `inherit (self) outPath lastModifiedDate;` via specialArgs.
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      homeStateVersion = "25.11";
      user = "sadiq";
      constants = import ./shared/constants.nix;
      nixpkgsConfig = {
        allowUnfree = true; # Allow proprietary packages
        allowBroken = false; # Don't allow broken packages
        allowInsecure = false; # Don't allow insecure packages
        allowUnsupportedSystem = false; # Don't allow unsupported systems
      };
      pkgs = import nixpkgs {
        inherit system;
        config = nixpkgsConfig;
        overlays = [
          inputs.niri.overlays.niri
          (final: prev: {
            # Disable tests for font-related Python packages that fail on NixOS.
            # These packages have network-based or font-rendering tests that don't
            # work in the Nix build sandbox. The packages themselves are fine.
            #
            # TODO: Track upstream fixes and remove overrides when tests pass.
            #   - picosvg: https://github.com/google/picosvg/issues
            #   - nanoemoji: https://github.com/googlefonts/nanoemoji/issues
            #   - gftools: https://github.com/googlefonts/gftools/issues
            # Review periodically (e.g. on each nixpkgs update).
            python3Packages = prev.python3Packages.overrideScope (
              pyFinal: pyPrev: {
                picosvg = pyPrev.picosvg.overridePythonAttrs (_: {
                  doCheck = false;
                });
                nanoemoji = pyPrev.nanoemoji.overridePythonAttrs (_: {
                  doCheck = false;
                });
                gftools = pyPrev.gftools.overridePythonAttrs (_: {
                  doCheck = false;
                });
              }
            );
          })
        ];
      };

      pkgsStable = import nixpkgs-stable {
        inherit system;
        config = nixpkgsConfig;
      };

      makeSystem =
        { hostname, stateVersion }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              stateVersion
              hostname
              user
              pkgsStable
              constants
              ;
          };
          modules = [ ./hosts/${hostname}/configuration.nix ];
        };

      makeHome =
        { hostname }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit
              inputs
              homeStateVersion
              user
              pkgsStable
              system
              hostname
              constants
              ;
          };
          modules = [
            ./home/home.nix
            inputs.stylix.homeModules.stylix
            inputs.niri.homeModules.config
            inputs.noctalia.homeModules.default
          ];
        };

      # Single source of truth — edit hosts/_inventory.nix to add/remove hosts.
      hosts = import ./hosts/_inventory.nix;
    in
    {
      nixosConfigurations = nixpkgs.lib.foldl' (
        configs: host:
        configs // { "${host.hostname}" = makeSystem { inherit (host) hostname stateVersion; }; }
      ) { } hosts;

      homeConfigurations = nixpkgs.lib.foldl' (
        configs: host: configs // { "${user}@${host.hostname}" = makeHome { inherit (host) hostname; }; }
      ) { } hosts;
    };
}
