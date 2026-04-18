# Host inventory — single source of truth for flake.nix.
# Used by: flake.nix (hosts binding)
# To add a host: append an entry here, then create hosts/<hostname>/configuration.nix.
[
  {
    hostname = "desktop";
    stateVersion = "25.11";
  }
  {
    hostname = "thinkpad";
    stateVersion = "25.11";
  }
]
