{
  description = "NixOS + Home-Manager flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
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

    # Noctalia v5: native C++ desktop shell (bar/launcher/control-center/
    # notifications/lock/power-menu). The ACTIVE shell — see home/noctalia/.
    # v5 is a fresh architecture (TOML config, Luau plugins) — does not conflict
    # with any v4 install. Binary: `noctalia`; IPC: `noctalia msg <command>`.
    # NOTE: v5 has NO Stylix target (unlike v4's noctalia-shell.enable); theme is
    # hand-mirrored via programs.noctalia.settings in home/noctalia/.
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia Greeter: greetd-based display manager matching the Noctalia shell
    # aesthetic. Replaces DankGreeter. Syncs palette/wallpaper/font from the
    # running shell via sync.toml. See nixos/modules/greetd.nix.
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
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
    # Agent CLIs and desktop apps update faster than the pinned nixpkgs.
    # Keep this input's own tested Nixpkgs pin instead of using `follows`.
    llm-agents.url = "github:numtide/llm-agents.nix";
    # Skill content only; pin it separately from the agent executables.
    mattPocockSkills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
    # Chrome DevTools skill content. The repo ships several skill bundles;
    # home/ai/skills.nix links only chrome-devtools-cli, which drives the
    # chrome-devtools binary built by home/ai/chrome-devtools.
    chromeDevToolsMcp = {
      url = "github:ChromeDevTools/chrome-devtools-mcp/ae0aaef884c41445d83f86f099ef211f4584b791";
      flake = false;
    };
    # UI/UX design skill bundles (banner, brand, design-system, ui-ux-pro-max…).
    # home/ai/skills.nix links every bundle and patches ui-ux-pro-max's
    # SKILL.md, whose commands only resolve inside a Claude plugin install.
    uiUxProMaxSkills = {
      url = "github:nextlevelbuilder/ui-ux-pro-max-skill/477bcb28c9812b385cb51a4605ddf30d7b2266e2";
      flake = false;
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
      homeStateVersion = "26.05";
      user = "sadiq";
      constants = import ./shared/constants.nix;
      nixpkgsConfig = {
        allowUnfree = true; # Allow proprietary packages
        # The Android SDK components used by the pi-re lab (packages/
        # android-re-toolchain) require explicit license acceptance.
        android_sdk.accept_license = true;
        allowBroken = false; # Don't allow broken packages
        allowInsecure = false; # Don't allow insecure packages
        allowUnsupportedSystem = false; # Don't allow unsupported systems
      };
      pkgs = import nixpkgs {
        inherit system;
        config = nixpkgsConfig;
        overlays = [
          # libdisplay-info_0_2 was removed from nixpkgs-unstable but niri's
          # overlay still requires exactly 0.2.0. Bridge it from niri's own
          # pinned nixpkgs (see niri input note: mesa compatibility).
          (_final: prev: {
            libdisplay-info_0_2 =
              inputs.niri.inputs.nixpkgs.legacyPackages.${_final.stdenv.hostPlatform.system}.libdisplay-info_0_2;
          })
          inputs.niri.overlays.niri
          (
            final: prev:
            let
              # Shared package overrides applied to every python interpreter so that
              # ALL package set references (python3Packages, python3.pkgs,
              # python313Packages, python313.pkgs) inherit them.
              # overrideScope on python3Packages alone only affects that one alias;
              # jetbrains-mono builds via python313, bypassing a python3-only override.
              pythonPackageOverrides = _: pyPrev: {
                picosvg = pyPrev.picosvg.overridePythonAttrs (_: {
                  doCheck = false;
                });
                # googlefonts moved the v0.16.0 tag upstream; nixpkgs' pinned
                # src hash is stale and fails on fresh builds (hash mismatch).
                # Pin the commit the tag currently points at. Remove once
                # nixpkgs updates the hash.
                nanoemoji = pyPrev.nanoemoji.overridePythonAttrs (_: {
                  src = prev.fetchFromGitHub {
                    owner = "googlefonts";
                    repo = "nanoemoji";
                    rev = "4e2ade0ab833eab1cfb6006edbfc96af5aa1d61e";
                    hash = "sha256-FysyKC01XBnRiur5RR9fcsTxQqE8x0JJHSoe3q6JtKc=";
                  };
                  doCheck = false;
                });
                gftools = pyPrev.gftools.overridePythonAttrs (_: {
                  doCheck = false;
                });
              };
            in
            {
              # OpenLDAP: test017-syncreplication-refresh is a known flaky test that
              # fails intermittently due to timing in sync replication checks.
              # Pulled in by lutris as a transitive dependency.
              openldap = prev.openldap.overrideAttrs (_: {
                doCheck = false;
              });
              # udiskie: test_keyutils uses kernel keyring syscalls (add_key,
              # keyctl_read) that fail in the Nix sandbox. Package itself works.
              udiskie = prev.udiskie.overridePythonAttrs (_: {
                doCheck = false;
              });
              # cloudflared 2026.8.x: TestReadClientEvent_InvalidWebSocketMessageType
              # panics with "Fail in goroutine after test has completed" — upstream
              # test race (a goroutine asserts via require.NoError after the test
              # returned). Deterministic under go 1.26.7. Remove once
              # upstream/nixpkgs ships the test fix.
              cloudflared = prev.cloudflared.overrideAttrs (_: {
                doCheck = false;
              });
              # typescript-language-server 6.0.2: fetchPnpmDeps content changed
              # after the 6.0.2 bump, so nixpkgs' pinned hash is stale and the
              # FOD fails on fresh builds (hash mismatch). Upstream fix:
              # nixpkgs ac7b1aaed "typescript-language-server: fix pnpm hash".
              # Remove once nixos-unstable absorbs it.
              typescript-language-server = prev.typescript-language-server.overrideAttrs (old: {
                pnpmDeps = old.pnpmDeps.override {
                  hash = "sha256-xR/EF60lVBsITKgH7wCM2wHM46PFQevD51KfCENSUH4=";
                };
              });
              python3 = prev.python3.override { packageOverrides = pythonPackageOverrides; };
              python3Packages = final.python3.pkgs;
              python313 = prev.python313.override { packageOverrides = pythonPackageOverrides; };
              python313Packages = final.python313.pkgs;
            }
          )
        ];
      };

      pkgsStable = import nixpkgs-stable {
        inherit system;
        config = nixpkgsConfig;
        overlays = [
          (_final: prev: {
            # OpenLDAP: test017-syncreplication-refresh is a known flaky test that
            # fails intermittently due to timing in sync replication checks.
            # Pulled in by bottles as a transitive dependency.
            openldap = prev.openldap.overrideAttrs (_: {
              doCheck = false;
            });
          })
        ];
      };

      # Rooted Android emulator lab for pi-re (home/ai/pi-re). Mirrors the
      # upstream lab settings this module was vendored from.
      androidLab = {
        acceptLicense = true;
        apiLevel = "35";
        imageType = "google_apis";
        abi = "x86_64";
        avdName = "pi-re-api35";
        port = 5580;
        cores = 4;
        memoryMiB = 4096;
        bootTimeoutSeconds = 180;
        gpuMode = "swangle";
        hardwareVideoDecoder = false;
        display = {
          width = 720;
          height = 1600;
          density = 320;
        };
        proxyPort = 8089;
      };
      # Built from the stable channel: the toolchain pins SDK components and
      # a Frida 17.5.1 server that unstable (Frida 17.19) no longer matches.
      androidTools = import ./packages/android-re-toolchain {
        pkgs = pkgsStable;
        inherit androidLab;
      };
      # Pinned REA static-analysis stack consumed by home/ai/pi-re.
      reaTools = import ./packages/rea { inherit pkgs; };

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
          modules = [
            ./hosts/${hostname}/configuration.nix
            inputs.noctalia-greeter.nixosModules.default
          ];
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
            aiPackages = inputs.llm-agents.packages.${system};
            # Consumed by home/ai/pi-re (vendored from an upstream layout that
            # passes a `setup` attrset to Home Manager modules).
            setup = { inherit androidLab; };
            inherit androidTools reaTools;
            inherit (inputs) mattPocockSkills chromeDevToolsMcp uiUxProMaxSkills;
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
