# Ephemeral server inventory.
#
# Imports servers.nix if it exists (gitignored, local-only).
# On a fresh clone before setup, returns an empty list so Nix eval
# doesn't crash. Run `cp servers.nix.example servers.nix` to create it.
if builtins.pathExists ./servers.nix then import ./servers.nix else [ ]
