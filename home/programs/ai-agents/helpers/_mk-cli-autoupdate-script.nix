{ pkgs }:
let
  # All globally-installed CLI tools tracked for auto-update.
  # Each entry: { binary, npmPackage, label }
  tools = [
    {
      binary = "claude";
      npmPackage = "@anthropic-ai/claude-code";
      label = "Claude Code CLI";
    }
    {
      binary = "opencode";
      npmPackage = "opencode-ai";
      label = "OpenCode CLI";
    }
    {
      binary = "codex";
      npmPackage = "@openai/codex";
      label = "Codex CLI";
    }
    {
      binary = "codegraph";
      npmPackage = "@colbymchenry/codegraph";
      label = "CodeGraph CLI";
    }
    {
      binary = "copilot";
      npmPackage = "@github/copilot";
      label = "GitHub Copilot CLI";
    }
    {
      binary = "mimo";
      npmPackage = "@mimo-ai/cli";
      label = "MiMoCode CLI";
    }
    {
      binary = "omp";
      npmPackage = "@oh-my-pi/pi-coding-agent";
      label = "Oh My Pi CLI";
    }
    {
      binary = "dsh";
      npmPackage = "@deepseek-ai/dsh";
      label = "DeepSeek Harness CLI";
      # bun's shim runs plain node; dsh-base mounts cordis-plugin-hmr which
      # requires --expose-internals. The Nix dsh wrapper provides it — drop the
      # shim so it cannot shadow the wrapper (~/.bun/bin precedes the profile).
      cleanup = ''rm -f "$HOME/.bun/bin/dsh"'';
    }
    {
      binary = "playwright-cli";
      npmPackage = "@playwright/cli";
      label = "Playwright CLI";
    }
    {
      binary = "agent-browser";
      npmPackage = "agent-browser";
      label = "Agent Browser";
    }
    {
      binary = "agent-device";
      npmPackage = "agent-device";
      label = "Agent Device";
    }
    {
      binary = "btca";
      npmPackage = "btca";
      label = "BTCA CLI";
    }
    {
      binary = "opensrc";
      npmPackage = "opensrc";
      label = "OpenSRC CLI";
    }
    {
      binary = "skills";
      npmPackage = "skills";
      label = "Skills CLI";
    }
  ];

  # Builder: generates a per-tool shell script that installs (if missing) or
  # updates (if npm registry has a newer version). Optional cleanup runs last
  # on every path (e.g. removing a broken bun bin shim shadowed by a Nix
  # wrapper earlier in PATH).
  mkScript =
    {
      binary,
      npmPackage,
      label,
      cleanup ? "",
    }:
    pkgs.writeShellScript "${binary}-autoupdate" ''
      export PATH="$HOME/.nix-profile/bin:$HOME/.bun/bin:$HOME/.local/bin:$BUN_INSTALL/bin:$PATH"
      if ! command -v ${binary} >/dev/null 2>&1; then
        echo "Installing ${label}..."
        bun install -g ${npmPackage}@latest
        echo "Installed ${label}"
      else
        # Version check: read installed version from package.json instead of executing
        # the binary — copilot --version crashes (ERR_MODULE_NOT_FOUND) and omp is a
        # bun-compiled binary with unreliable --version output. Patterns accept
        # prerelease/build suffixes (e.g. dsh 0.1.0-rc.7) and only match semver-shaped
        # values — plain-semver regexes parsed rc versions as empty, and matching any
        # value grabbed `scripts.version` shell commands from registry manifests
        # (agent-browser et al.), both forcing a reinstall every run.
        pkg_json="$HOME/.bun/install/global/node_modules/${npmPackage}/package.json"
        ver_semver='[0-9]+(\.[0-9]+)+(-[0-9A-Za-z.]+)?(\+[0-9A-Za-z.]+)?'
        ver_key="\"version\"[[:space:]]*:[[:space:]]*\"$ver_semver\""
        if [[ -f "$pkg_json" ]]; then
          installed="$(grep -oE "$ver_key" "$pkg_json" | head -1 | grep -oE "$ver_semver")"
        else
          installed="$(${binary} --version 2>/dev/null | grep -oE "$ver_semver" | head -1)"
        fi

        latest="$(${pkgs.curl}/bin/curl -sf "https://registry.npmjs.org/${npmPackage}/latest" 2>/dev/null | grep -oE "$ver_key" | head -1 | grep -oE "$ver_semver")"

        if [[ -z "$latest" ]]; then
          echo "Could not resolve latest version for ${label} — skipping update (installed: ''${installed:-unknown})"
        elif [[ -n "$installed" && "$installed" == "$latest" ]]; then
          echo "${label} already at latest v$installed"
        else
          echo "Updating ${label} (installed: ''${installed:-unknown}, latest: $latest)..."
          bun install -g ${npmPackage}@latest
          echo "Updated ${label}"
        fi
      fi
      ${cleanup}
    '';
in
{
  inherit tools mkScript;
}
