# Host inventory — single source of truth for flake.nix.
# Used by: flake.nix (hosts binding)
# To add a host: append an entry here, then create hosts/<hostname>/configuration.nix.
[
  {
    hostname = "desktop";
    stateVersion = "26.05";
  }
  {
    hostname = "thinkpad";
    stateVersion = "26.05";
  }
]
