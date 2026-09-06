{ lib, pkgs }:
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
        # Retry: Persistent timer catch-up can fire before the network is up
        # (seen as ConnectionRefused at boot). Without the verify+exit below,
        # a failed install still echoed "Installed" and exited 0, so systemd
        # reported SUCCESS and nothing retried for a week.
        ok=0
        for attempt in 1 2 3; do
          if bun install -g ${npmPackage}@latest; then ok=1; break; fi
          echo "  ${label}: attempt $attempt failed — retrying in 15s"
          sleep 15
        done
        if [[ $ok == 1 ]] && command -v ${binary} >/dev/null 2>&1; then
          echo "Installed ${label}"
        else
          echo "ERROR: failed to install ${label} (${npmPackage})" >&2
          exit 1
        fi
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
  # Presence heal used by home activation: installs every tool whose bun
  # package dir is missing, in ONE bun invocation. The package dir (not
  # command -v) is the truth — a pruned package leaves a broken bin symlink
  # (command -v correctly fails) or, for dsh, a valid Nix wrapper pointing at
  # a nonexistent node_modules path. No version checks, no network when
  # healthy; freshness is the weekly timer's job.
  installIfMissingScript = pkgs.writeShellScript "ai-agents-install-missing" ''
      export PATH="$HOME/.nix-profile/bin:$HOME/.bun/bin:$HOME/.local/bin:$BUN_INSTALL/bin:$PATH"
      missing=()
    ${lib.concatMapStringsSep "\n" (tool: ''
      [[ -d "$HOME/.bun/install/global/node_modules/${tool.npmPackage}" ]] || missing+=(${tool.npmPackage})
    '') tools}
      if ((''${#missing[@]} > 0)); then
        echo "Installing missing AI agent CLIs: ''${missing[*]}"
        bun install -g "''${missing[@]}" \
          || echo "⚠ bun install failed — retry with: systemctl --user start ai-agents-autoupdate"
      fi
  '';
in
{
  inherit tools mkScript installIfMissingScript;
}
