# Nix package manager configuration (flakes, GC, etc.).
# This module configures the Nix package manager with optimized settings
# for performance, storage management, and development workflow.
{ inputs, ... }: {
  # Overlays applied to the NixOS nixpkgs (including pkgsi686Linux for 32-bit deps).
  # These apply to ALL package sets in the NixOS build, unlike overlays in flake.nix
  # which only affect the pkgs set passed to Home-Manager.
  nixpkgs.overlays = [
    # libdisplay-info_0_2 bridge: niri overlay requires 0.2.0 which was
    # removed from nixpkgs-unstable; source it from niri's pinned nixpkgs.
    (_final: prev: {
      libdisplay-info_0_2 = inputs.niri.inputs.nixpkgs.legacyPackages.${prev.system}.libdisplay-info_0_2;
    })
    inputs.niri.overlays.niri
    (
      final: prev:
      let
        # Shared package overrides applied to every python interpreter so that
        # ALL package set references inherit them (same pattern as flake.nix).
        pythonPackageOverrides = _: pyPrev: {
          # Valkey (python client): test_bgsave races against itself — fires a
          # second BGSAVE before the first completes on busy builders.
          # Transitive dep of onionshare-cli → firejail-wrapped-binaries.
          valkey = pyPrev.valkey.overridePythonAttrs (_: {
            doCheck = false;
          });
        };
      in
      {
        # OpenLDAP: test017-syncreplication-refresh is a known flaky test that
        # fails intermittently due to timing in sync replication checks.
        # Pulled in as a transitive dependency by lutris (via wine → 32-bit openldap).
        openldap = prev.openldap.overrideAttrs (_: {
          doCheck = false;
        });
        # mat2: MP4 metadata cleaning test fails due to ffmpeg version differences
        # in the sandbox. Package itself works fine.
        mat2 = prev.mat2.overridePythonAttrs (_: {
          doCheck = false;
        });
        python3 = prev.python3.override { packageOverrides = pythonPackageOverrides; };
        python3Packages = final.python3.pkgs;
      }
    )
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

      # Substituter robustness on a flaky link — the mirror of the NIX_CURL_FLAGS
      # fix below, but for cache.nixos.org nar pulls, which use Nix's INTERNAL
      # libcurl downloader (not fetchurl's curl, so NIX_CURL_FLAGS doesn't apply).
      # Without these, a single TCP reset tears down a multiplexed HTTP/2 stream
      # and bursts of "Stream error in the HTTP/2 framing layer" / timeouts kill
      # nar downloads (e.g. VirtualBox-7.2.10.tar.bz2), cascading into "no
      # substituter can build it" and a failed closure. http2=false forces
      # HTTP/1.1 so each nar is its own connection — a drop fails only that one
      # transfer, which Nix then retries. Confirmed levers: `nix show-config`.
      http2 = false;
      download-attempts = 10; # default 5; extra chances when a nar times out

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

  # Pass extra curl flags to fetchurl builds via the Nix daemon environment.
  # nixpkgs fetchurl hardcodes --retry 3 --retry-all-errors (builder.sh).
  # NIX_CURL_FLAGS is in fetchurl's impureEnvVars and is appended LAST, so these
  # override. --retry 100 gives curl many chances to push through the SSL EOF /
  # connection-reset drops seen on us.download.nvidia.com and edgedl.me.gvt1.com;
  # with -C - each retry is cheap because it resumes from the partial file, so a
  # high ceiling removes the retry-exhaustion cliff without wasting bandwidth.
  # The ~400 MB NVIDIA .run and ~1.2 GB Android Studio tarball would otherwise
  # burn the default budget on a flaky link and never converge.
  systemd.services.nix-daemon.environment.NIX_CURL_FLAGS = "--retry 100 --retry-delay 3 -C -";

  # Runtime bridge so the CURRENT `nh os switch` build picks up the http2
  # substituter setting above without waiting for a successful switch to
  # regenerate /etc/nix/nix.conf (catch-22: the build that would activate it
  # runs under the old daemon, where http2=true still causes the HTTP/2 stream
  # errors). NIX_CONFIG overrides nix.conf for the daemon on restart. Only one
  # setting here — systemd Environment= cannot hold the newline that NIX_CONFIG
  # needs for multiple — but http2 is the decisive lever; download-attempts
  # takes effect via nix.settings on the next successful switch.
  # Applied to the running daemon by scripts/build/fetch-retry.sh.
  systemd.services.nix-daemon.environment.NIX_CONFIG = "http2 = false";
}
