{ pkgs }:
{
  binary,
  npmPackage,
  label,
}:
pkgs.writeShellScript "${binary}-autoupdate" ''
  export PATH="$HOME/.bun/bin:$HOME/.local/bin:$BUN_INSTALL/bin:$PATH"
  if ! command -v ${binary} >/dev/null 2>&1; then
    echo "Installing ${label}..."
    if command -v ${pkgs.bun}/bin/bun >/dev/null 2>&1; then
      ${pkgs.bun}/bin/bun install -g ${npmPackage}@latest
    else
      ${pkgs.nodejs_22}/bin/npm install -g ${npmPackage}@latest
    fi
    echo "Installed ${label}"
    exit 0
  fi

  # Version check: compare installed vs latest from registry.
  # Saves ~50-500MB per run by skipping the full install when already current.
  installed="$(${binary} --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  latest="$(${pkgs.nodejs_22}/bin/npm view "${npmPackage}" version 2>/dev/null | tr -d ' \n\r')"

  if [[ -n "$installed" && -n "$latest" && "$installed" == "$latest" ]]; then
    echo "${label} already at latest v$installed"
    exit 0
  fi

  echo "Updating ${label} (installed: $installed, latest: $latest)..."

  binary_path="$(readlink -f "$(command -v ${binary})")"

  if [[ "$binary_path" == *"/.bun/install/global/"* ]]; then
    ${pkgs.bun}/bin/bun install -g ${npmPackage}@latest
  elif [[ "$binary_path" == *"/.npm-global/"* ]]; then
    ${pkgs.nodejs_22}/bin/npm install -g ${npmPackage}@latest
  elif command -v bun >/dev/null 2>&1; then
    bun install -g ${npmPackage}@latest
  elif command -v npm >/dev/null 2>&1; then
    npm install -g ${npmPackage}@latest
  else
    echo "No supported package manager found for ${label} auto-update"
    exit 1
  fi

  echo "Updated ${label}"
''
