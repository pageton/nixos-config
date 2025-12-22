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
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixcord.url = "github:kaylorben/nixcord";
    vicinae.url = "github:vicinaehq/vicinae";
    nvf.url = "github:notashelf/nvf";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    # self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    homeStateVersion = "25.11";
    user = "sadiq";
    pkgs = import nixpkgs {
      inherit system;
      allowUnfree = true; # Allow proprietary packages
      allowBroken = true; # Don't allow broken packages
      allowInsecure = false; # Don't allow insecure packages
      allowUnsupportedSystem = false; # Don't allow unsupported systems
    };

    pkgsStable = import nixpkgs-stable {
      inherit system;
      allowUnfree = true;
      allowBroken = false;
      allowInsecure = false;
      allowUnsupportedSystem = false;
    };

    makeSystem = {
      hostname,
      stateVersion,
    }:
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
          inputs.disko.nixosModules.disko
          inputs.stylix.nixosModules.stylix
        ];
      };

    makeHome = {
      hostname,
    }:
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
            ;
        };
        modules = [
          ./home/home.nix
          inputs.stylix.homeModules.stylix
        ];
      };

    hosts = [
      {
        hostname = "desktop";
        stateVersion = "25.11";
      }
      {
        hostname = "thinkpad";
        stateVersion = "25.11";
      }
      {
        hostname = "server";
        stateVersion = "25.11";
      }
    ];
  in {
    nixosConfigurations =
      nixpkgs.lib.foldl' (
        configs: host:
          configs // {"${host.hostname}" = makeSystem {inherit (host) hostname stateVersion;};}
      ) {}
      hosts;

    homeConfigurations =
      nixpkgs.lib.foldl' (
        configs: host:
          configs // {"${user}@${host.hostname}" = makeHome {inherit (host) hostname;};}
      ) {}
      hosts;
  };
}
