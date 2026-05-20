# Nix package manager configuration (flakes, GC, etc.).
# This module configures the Nix package manager with optimized settings
# for performance, storage management, and development workflow.
{ inputs, ... }:
{
  # Overlays applied to the NixOS nixpkgs (including pkgsi686Linux for 32-bit deps).
  # These apply to ALL package sets in the NixOS build, unlike overlays in flake.nix
  # which only affect the pkgs set passed to Home-Manager.
  nixpkgs.overlays = [
    inputs.niri.overlays.niri
    (final: prev: {
      # OpenLDAP: test017-syncreplication-refresh is a known flaky test that
      # fails intermittently due to timing in sync replication checks.
      # Pulled in as a transitive dependency by lutris (via wine → 32-bit openldap).
      openldap = prev.openldap.overrideAttrs (_: {
        doCheck = false;
      });

      # Valkey (python client): test_bgsave races against itself — fires a second
      # BGSAVE before the first completes on busy builders. Transitive dep of
      # onionshare-cli → firejail-wrapped-binaries.
      python3Packages = prev.python3Packages.overrideScope (
        pyFinal: pyPrev: {
          valkey = pyPrev.valkey.overridePythonAttrs (_: {
            doCheck = false;
          });
        }
      );
    })
  ];

  nix = {
    # Define channels for legacy nix commands
    nixPath = [
      "nixpkgs=${inputs.nixpkgs}" # Point nixpkgs to our flake input
    ];

    settings = {
      # Enable modern Nix features
      experimental-features = [
        "nix-command" # Enable modern nix commands
        "flakes" # Enable flake support
      ];

      # Automatic store optimization
      auto-optimise-store = true; # Deduplicate identical files

      # Build parallelism
      max-jobs = "auto"; # Up to 12 parallel derivations on 7600X
      cores = 4; # Cap per-derivation threads (was 0 = unlimited)
      # VirtualBox kBuild, LLVM, etc. would eat all 12 threads with cores=0.
      # 4 keeps builds fast while leaving headroom for the desktop.

      # Storage optimization thresholds
      min-free = 128000000; # 128MB - Start optimizing when free space is low
      max-free = 1000000000; # 1GB - Stop optimizing at this threshold

      # Memory and stability improvements
      keep-outputs = true; # Keep build outputs for faster rebuilds
      keep-derivations = true; # Keep derivations for development
      sandbox = true; # Enable build sandboxing for security
      trusted-users = [ "sadiq" ];
      sandbox-fallback = false; # Don't fallback to non-sandboxed builds

      # Limit resource usage to prevent system overload
      max-substitution-jobs = 8; # Max parallel downloads
      http-connections = 25; # Max HTTP connections for downloads

      download-buffer-size = 262144000; # 250 MB (250 * 1024 * 1024)

      substituters = [
        # high priority since it's almost always used
        "https://cache.nixos.org?priority=10"
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      ];
    };

    # Garbage collection configuration
    gc = {
      automatic = true; # Enable automatic garbage collection
      dates = "weekly"; # Run weekly
      options = "--delete-older-than 14d --max-freed $((64 * 1024**3))"; # Keep 14 days, max 64GB freed
    };
  };
}
