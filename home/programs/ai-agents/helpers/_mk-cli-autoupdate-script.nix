{ pkgs }:
{
  binary,
  npmPackage,
  label,
}:
pkgs.writeShellScript "${binary}-autoupdate" ''
  export PATH="$HOME/.nix-profile/bin:$HOME/.bun/bin:$HOME/.local/bin:$BUN_INSTALL/bin:$PATH"
  if ! command -v ${binary} >/dev/null 2>&1; then
    echo "Installing ${label}..."
    bun install -g ${npmPackage}@latest
    echo "Installed ${label}"
    exit 0
  fi

  # Version check: read installed version from package.json instead of executing
  # the binary — copilot --version crashes (ERR_MODULE_NOT_FOUND) and omp is a
  # bun-compiled binary with unreliable --version output.
  pkg_json="$HOME/.bun/install/global/node_modules/${npmPackage}/package.json"
  if [[ -f "$pkg_json" ]]; then
    installed="$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[0-9]+\.[0-9]+\.[0-9]+"' "$pkg_json" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  else
    installed="$(${binary} --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  fi

  latest="$(${pkgs.curl}/bin/curl -sf "https://registry.npmjs.org/${npmPackage}/latest" 2>/dev/null | grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"

  if [[ -n "$installed" && -n "$latest" && "$installed" == "$latest" ]]; then
    echo "${label} already at latest v$installed"
    exit 0
  fi

  echo "Updating ${label} (installed: $installed, latest: $latest)..."

  bun install -g ${npmPackage}@latest

  echo "Updated ${label}"
''
