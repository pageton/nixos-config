{
  description = "NixOS + Home-Manager flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      homeStateVersion = "25.05";
      user = "sadiq";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          inputs.neovim-nightly-overlay.overlays.default
        ];
      };

      pkgsStable = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
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
              ;
          };
          modules = [
            ./hosts/${hostname}/configuration.nix
            inputs.stylix.nixosModules.stylix
          ];
        };

      hosts = [
        {
          hostname = "desktop";
          stateVersion = "25.05";
        }
        {
          hostname = "thinkpad";
          stateVersion = "25.05";
        }
      ];
    in
    {
      nixosConfigurations = nixpkgs.lib.foldl' (
        configs: host:
        configs
        // {
          "${host.hostname}" = makeSystem {
            inherit (host) hostname stateVersion;
          };
        }
      ) { } hosts;

      homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit
            inputs
            homeStateVersion
            user
            pkgsStable
            system
            ;
        };

        modules = [
          ./home/home.nix
          inputs.stylix.homeModules.stylix
        ];
      };
    };
}
