# Install the Pi configuration vendored at ./pi (see pi/README.md) into
# ~/.pi/agent/{extensions,skills}. The README's manual workflow — copy files,
# `npm install` per extension, a venv for pdf-reader, and
# `npx playwright install chromium` — is replaced by store-built artifacts:
#
#   extensions with package.json  -> offline `npm ci` via npmConfigHook
#   browser                        -> executablePath pinned to nixpkgs
#                                     ungoogled-chromium; mutable profile
#                                     moved under ~/.cache/pi
#   web-search                     -> auth.json redirected to a writable
#                                     ~/.config path (see below)
#   pdf-reader                     -> .venv symlinked to python3.withPackages
#   youtube-transcript deps        -> yt-dlp + ffmpeg on PATH
#
# Mutable state (settings.json, auth.json, models-store.json, sessions/)
# stays in the user's home untouched — same philosophy as default.nix.
# README-only stubs (interactive-subagents, observational-memory) are not
# installed; their real code lives in separate upstream repos.

{
  piBtw,
  piInteractiveSubagents,
  piObservationalMemory,
  pkgs,
  ...
}:

let
  # Vendored config at the repo root (github.com/EeroAlvar/pi-config).
  piConfig = ../../pi;

  # Build a Pi extension that ships npm deps: a sandboxed offline `npm ci`
  # (npmConfigHook) producing one store path holding index.ts + package.json
  # + node_modules. The deps MUST be siblings of index.ts inside that path:
  # Node resolves imports from a module's real (symlink-resolved) path, so a
  # node_modules link placed next to a symlinked index.ts would never be found.
  buildNpmExtension =
    {
      name,
      npmDepsHash,
      postPatch ? "",
    }:
    pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      pname = "pi-extension-${name}";
      version = "1";
      src = piConfig + "/extensions/${name}";

      npmDeps = pkgs.fetchNpmDeps {
        inherit (finalAttrs) pname version src;
        hash = npmDepsHash;
      };

      nativeBuildInputs = [
        # nodejs ships npm itself; no separate package.
        pkgs.nodejs
        # Validates the lockfile against npmDeps, then runs the offline
        # `npm ci --ignore-scripts` + `npm rebuild` during patchPhase,
        # leaving node_modules/ in the build directory.
        pkgs.npmHooks.npmConfigHook
      ];

      inherit postPatch;

      dontConfigure = true;
      dontBuild = true;
      dontFixup = true; # pure JS/TS data; nothing to strip or patchelf

      installPhase = ''
        runHook preInstall
        mkdir -p "$out"
        cp -r index.ts package.json node_modules "$out/"
        runHook postInstall
      '';
    });

  # bash-guard is intentionally NOT deployed (kept vendored for reference);
  # the user opted out of its command blocking.

  webFetch = buildNpmExtension {
    name = "web-fetch";
    npmDepsHash = "sha256-Rbdj6jd25Urxr1wJj1Vl7mefv1IKu5zQhHgt6dOEqaU=";
  };

  # playwright-core never downloads browsers on its own, so the README's
  # `npx playwright install chromium` becomes an explicit executablePath into
  # the same nixpkgs ungoogled-chromium that chrome-devtools-mcp uses
  # (pnpm-tools.nix). The persistent profile is moved under ~/.cache/pi
  # because the linked extension dir is a read-only store path — the default
  # .profile inside it would fail to launch. PI_BROWSER_PROFILE / _HEADFUL
  # env overrides keep working unchanged.
  browser = buildNpmExtension {
    name = "browser";
    npmDepsHash = "sha256-dh+GrLV8hftXbtmY+HjlsQNwK59KWCmxsL7AerYSKOs=";
    postPatch = ''
      substituteInPlace index.ts \
        --replace-fail 'join(homedir(), ".pi", "agent", "extensions", "browser", ".profile")' \
          'join(homedir(), ".cache", "pi", "browser-profile")' \
        --replace-fail 'chromium.launchPersistentContext(profileDir, {' \
          'chromium.launchPersistentContext(profileDir, { executablePath: "${pkgs.ungoogled-chromium}/bin/chromium",'
    '';
  };

  # web-search has no npm deps; the only change is where credentials are read
  # from. EXT_DIR resolves to the read-only store path once linked, so the
  # upstream EXT_DIR/auth.json location is redirected to a writable config
  # file — copy auth.example.json there once. The GOOGLE_SEARCH_API_KEY /
  # GOOGLE_CSE_ID env vars keep working unchanged.
  webSearch = pkgs.stdenvNoCC.mkDerivation {
    pname = "pi-extension-web-search";
    version = "1";
    src = piConfig + "/extensions/web-search";
    postPatch = ''
      substituteInPlace index.ts \
        --replace-fail 'const AUTH_PATH = path.join(EXT_DIR, "auth.json");' \
          'const AUTH_PATH = process.env.HOME + "/.config/pi/web-search-auth.json";'
    '';
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      cp -r . "$out"
      runHook postInstall
    '';
  };

  # pi-observational-memory: tiered subprocess-backed memory (/om; OFF by
  # default, toggled per session). Zero runtime npm deps; observer and
  # consolidator workers are `pi` subprocesses that write to the project's
  # .memory/ dir, never to the extension dir.
  #
  # Local patch (upstream has no setting for it): worker models
  # openrouter/z-ai/glm-5.3 -> zai/glm-5.3-flash, so observers/consolidators
  # use the cheap model on existing z.ai auth (override via the
  # `observational-memory` namespace in ~/.pi/agent/settings.json).
  #
  # The repo's pi manifest points at src/index.ts while pi's directory
  # auto-discovery wants a root index.ts. Converge both on ONE module — a
  # root forwarder plus a patched manifest — so the extension registers
  # exactly once regardless of which discovery path pi takes.
  observationalMemory = pkgs.stdenvNoCC.mkDerivation {
    pname = "pi-extension-observational-memory";
    version = "0.1.0";
    src = piObservationalMemory;
    postPatch = ''
      substituteInPlace package.json \
        --replace-fail '"./src/index.ts"' '"./index.ts"'
      substituteInPlace src/config.ts \
        --replace-fail 'provider: "openrouter", id: "z-ai/glm-5.3", thinking: "low"' \
          'provider: "zai", id: "glm-5.3-flash", thinking: "low"' \
        --replace-fail 'provider: "openrouter", id: "z-ai/glm-5.3", thinking: "medium"' \
          'provider: "zai", id: "glm-5.3-flash", thinking: "medium"'
      cat > index.ts <<'EOF'
      // Nix-assembled entry: converge manifest + auto-discovery on one module.
      export { default } from "./src/index.ts";
      export * from "./src/index.ts";
      EOF
    '';
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r src agent package.json index.ts README.md LICENSE "$out/"
      runHook postInstall
    '';
  };

  # pi-interactive-subagents: async subagents in tmux panes with a live
  # status widget. Zero runtime npm deps. Same manifest/root-index.ts
  # convergence as above; the pi-extension/subagents + agents layout is kept
  # intact because bundled agent discovery resolves <extension>/agents
  # relative to the module files.
  interactiveSubagents = pkgs.stdenvNoCC.mkDerivation {
    pname = "pi-extension-interactive-subagents";
    version = "3.7.2";
    src = piInteractiveSubagents;
    postPatch = ''
      substituteInPlace package.json \
        --replace-fail '"./pi-extension/subagents/index.ts"' '"./index.ts"'
      # Bundled scout/researcher/worker agents ship pinned to OpenRouter;
      # switch them to the z.ai provider already authenticated via /login so
      # they run without extra credentials. Override per agent anytime with
      # ~/.pi/agent/agents/<name>.md (global) or .pi/agents/ (project).
      substituteInPlace agents/scout.md agents/researcher.md agents/worker.md \
        --replace-fail 'openrouter/z-ai/glm-5.3' 'zai/glm-5.3'
      # The extension dir is a read-only store path, so the upstream
      # config.json-in-extension-dir customization route is redirected to a
      # writable file; when absent it still falls back to the bundled
      # example (status widget enabled).
      substituteInPlace pi-extension/subagents/status.ts \
        --replace-fail 'join(PACKAGE_ROOT, "config.json")' \
          'process.env.HOME + "/.config/pi/interactive-subagents/config.json"'
      cat > index.ts <<'EOF'
      // Nix-assembled entry: converge manifest + auto-discovery on one module.
      export { default } from "./pi-extension/subagents/index.ts";
      export * from "./pi-extension/subagents/index.ts";
      EOF
    '';
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r pi-extension agents package.json index.ts config.json.example README.md LICENSE "$out/"
      runHook postInstall
    '';
  };

  # pdf-reader expects a venv at SKILL_DIR/.venv (scripts run as
  # `SKILL_DIR/.venv/bin/python ...`). A symlink to a python3.withPackages
  # env satisfies that without any pip/venv step. requirements.txt pins
  # PyMuPDF 1.27.2.2; nixpkgs ships a compatible 1.27.x.
  pdfReaderPython = pkgs.python3.withPackages (ps: [ ps.pymupdf ]);
  pdfReader = pkgs.stdenvNoCC.mkDerivation {
    pname = "pi-skill-pdf-reader";
    version = "1";
    src = piConfig + "/skills/pdf-reader";
    postPatch = ''
      substituteInPlace SKILL.md \
        --replace-fail 'If the venv is missing, create it from `requirements.txt`:' \
          'The venv is provided by Nix (home/ai/pi.nix) — never create or modify it.' \
        --replace-fail 'python3 -m venv SKILL_DIR/.venv' \
          '# venv provided by Nix' \
        --replace-fail 'SKILL_DIR/.venv/bin/pip install -r SKILL_DIR/requirements.txt' \
          '# no pip step needed'
    '';
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      cp -r . "$out"
      ln -s ${pdfReaderPython} "$out/.venv"
      runHook postInstall
    '';
  };
in
{
  # youtube-transcript runtime (README "Dependencies": yt-dlp + ffmpeg).
  # ffmpeg is already on PATH via home/packages/multimedia.nix (pkgsStable),
  # and python3 for analyze-sessions / youtube-transcript comes via herdr.nix.
  home.packages = [ pkgs.yt-dlp ];

  # Whole-directory links: each entry is self-contained. prompt-snippets
  # resolves its snippets/ dir relative to the module path, so snippets are
  # edited in this repo and picked up on the next switch (then /reload in pi).
  home.file = {
    # Extensions with no external deps, linked straight from the repo.
    ".pi/agent/extensions/ask-user-question.ts".source = piConfig + "/extensions/ask-user-question.ts";
    ".pi/agent/extensions/custom-header.ts".source = piConfig + "/extensions/custom-header.ts";
    ".pi/agent/extensions/prompt-snippets".source = piConfig + "/extensions/prompt-snippets";

    # Extensions with built artifacts.
    ".pi/agent/extensions/web-fetch".source = webFetch;
    ".pi/agent/extensions/browser".source = browser;
    ".pi/agent/extensions/web-search".source = webSearch;

    # Pinned external extensions (flake inputs, see flake.nix). pi-btw is
    # self-contained (no npm deps, no file writes next to the module), so a
    # plain link is safe; the others are assembled above.
    ".pi/agent/extensions/btw.ts".source = piBtw + "/extensions/btw.ts";
    ".pi/agent/skills/btw".source = piBtw + "/skills/btw";
    ".pi/agent/extensions/pi-observational-memory".source = observationalMemory;
    ".pi/agent/extensions/pi-interactive-subagents".source = interactiveSubagents;

    # Skills. pdf-reader carries its Nix-provided .venv; the rest are static.
    ".pi/agent/skills/analyze-sessions".source = piConfig + "/skills/analyze-sessions";
    ".pi/agent/skills/web-debug".source = piConfig + "/skills/web-debug";
    ".pi/agent/skills/youtube-transcript".source = piConfig + "/skills/youtube-transcript";
    ".pi/agent/skills/pdf-reader".source = pdfReader;
  };
}
