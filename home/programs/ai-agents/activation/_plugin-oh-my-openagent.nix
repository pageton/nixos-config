# Install oh-my-openagent plugin in omo profile config directories.
# OpenCode doesn't auto-install plugins from the plugin array — the npm package
# must be present in the profile's node_modules. This activation script runs
# `bun add` for each omo profile on every home-manager switch.

{ config, lib }:

let
  omoProfiles = import ../helpers/_omo-profiles.nix { inherit config; };
in
lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  echo "📦 Installing oh-my-openagent plugin for omo profiles..."

  for profile in ${lib.concatStringsSep " " (map (n: lib.escapeShellArg n) omoProfiles.names)}; do
    dir="$HOME/.config/$profile"
    if [[ -d "$dir" ]]; then
      # Skip if already installed at the correct version
      if [[ -d "$dir/node_modules/oh-my-openagent" ]]; then
        echo "✓ oh-my-openagent already installed for $profile"
        continue
      fi

      echo "  Installing oh-my-openagent in $profile..."
      if command -v bun >/dev/null 2>&1; then
        (cd "$dir" && bun add oh-my-openagent@latest >/dev/null 2>&1 && echo "  ✓ $profile") || echo "  ✗ Failed to install for $profile"
      else
        echo "  ✗ bun not found — skipping oh-my-openagent install for $profile"
      fi
    fi
  done
''
