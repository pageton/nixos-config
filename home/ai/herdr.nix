# Configure Herdr and its pinned Smart Rename plugin without storing credentials.

{
  aiPackages,
  lib,
  pkgs,
  ...
}:

let
  smartRenameSource = pkgs.fetchFromGitHub {
    owner = "iurysza";
    repo = "herdr-tab-smart-rename";
    # v0.6.1: includes fix #46 (progress marker cleared when Herdr trims the
    # empty-label marker) — same empty-label area the vendored patch guards.
    rev = "f66cd1050e6feebfe55f81a2a3962f63b628ba95";
    hash = "sha256-aYxJLFBL7nPEbN2S/wgdEJYEso9B48uWFLeKk55lk4E=";
  };
  # Fetch the frozen production dependencies; lifecycle scripts never run.
  smartRenameDependencies = pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr-smart-rename-dependencies";
    version = "0.6.1";
    src = smartRenameSource;
    nativeBuildInputs = [ bun ];
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;
    installPhase = ''
      bun install --frozen-lockfile --production --ignore-scripts \
        --backend copyfile --cache-dir "$TMPDIR/bun-cache"
      cp -R node_modules "$out"
    '';
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-zeTMifSOYK/2YwSxloArreESy+rg238Oo8cjL/s1vMc=";
  };
  smartRename = pkgs.runCommand "herdr-smart-rename-0.6.1" { } ''
    pluginDir="$out/share/herdr/plugins/smart-rename"
    mkdir -p "$pluginDir"
    cp -R ${smartRenameSource}/. "$pluginDir/"
    chmod -R u+w "$pluginDir"
    # Upstream 0.6.0 treats every externally observed label change as a
    # manual edit, so a Herdr reset to a numbered default (tab renumbering
    # or a cleared name) permanently locks "manual ownership" and stops
    # automatic renames. Reclaim numbered defaults as unnamed targets
    # instead; empty pane labels still preserve manual names. Also rename
    # directly on task switches (100ms task cooldown — cost tracks task
    # switches via fingerprint changes, not the timer — with 5s worker
    # sweeps as the pickup for transcripts that lag the agent-start event)
    # instead of waiting out the 10-minute same-target rate limit. Both
    # patches mirror PR #45 review feedback:
    # numbered reclamation is tab/workspace only, panes keep numeric names.
    patch --no-backup-if-mismatch -d "$pluginDir" -p1 \
      < ${./herdr-smart-rename-reclaim-numbered-defaults.patch}
    patch --no-backup-if-mismatch -d "$pluginDir" -p1 \
      < ${./herdr-smart-rename-rename-on-task-switch.patch}
    # Keep the node_modules directory name in resolved paths for package imports.
    cp -R ${smartRenameDependencies} "$pluginDir/node_modules"
    ${lib.getExe pkgs.python3} - "$pluginDir/herdr-plugin.toml" \
      ${lib.getExe bun} ${lib.getExe pkgs.bash} <<'PY'
    import json
    import pathlib
    import sys

    manifest = pathlib.Path(sys.argv[1])
    text = manifest.read_text()
    build = '[[build]]\ncommand = ["bun", "install", "--production", "--frozen-lockfile"]\n\n'
    if build not in text:
        raise SystemExit("Smart Rename's build manifest changed; review its dependencies")
    text = text.replace(build, "").replace('["bun",', '[' + json.dumps(sys.argv[2]) + ',')
    # Restore the worker with its Herdr session once a model has been selected.
    startup = 'if [ -s "$HERDR_PLUGIN_CONFIG_DIR/model-selection.json" ]; then exec ' + sys.argv[2] + ' src/cli.ts start; fi'
    text += '\n[[startup]]\ncommand = ' + json.dumps([sys.argv[3], "-c", startup]) + '\n'
    manifest.write_text(text)
    PY
  '';
  herdr = lib.getExe aiPackages.herdr;
  # Reuse the repo's pinned Bun 1.3.14 (home/programs/languages/javascript.nix)
  # instead of nixpkgs' bun — avoids a bin/bunx collision in home-manager-path
  # and keeps every Bun consumer on the version the agent CLIs are pinned to.
  bun = import ../_helpers/_bun-package.nix { inherit pkgs; };
in

{
  home = {
    # The bundled Codex SessionStart hook silently skips reporting without
    # python3. Bun is not repeated here — the pinned runtime is already on
    # PATH via home/programs/languages/javascript.nix.
    packages = [
      pkgs.python3
      smartRename
    ];

    # Agent integrations report pane sessions and agent state to the running
    # Herdr server. Without them tab-smart-rename reads no transcript and
    # every naming attempt answers "no meaningful task". Pi's integration is
    # plain extension code in a directory home-manager owns, so it ships from
    # the pinned Herdr package — `herdr integration install pi` cannot
    # survive a switch (it also fails writing through the read-only symlink).
    # OpenCode's installer additionally edits user-writable config
    # (tui.jsonc) in a tree home-manager does not own, so it stays imperative
    # — as do the hook-script agents (claude, codex, qwen, …): run
    # `herdr integration install <agent>`.
    file.".pi/agent/extensions/herdr-agent-state.ts" = {
      source = "${aiPackages.herdr}/share/herdr/integrations/pi/herdr-agent-state.ts";
      force = true;
    };

    # Herdr owns the registry and private model selection; Nix owns plugin
    # code.
    activation.registerHerdrSmartRename = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${herdr} plugin link ${smartRename}/share/herdr/plugins/smart-rename
      # A worker started by the server from an older plugin generation keeps
      # running after upgrades and fights the pinned worker over the shared
      # state file (upstream 0.6.1 does not reap it). Stop stale generations.
      for pid in $(${pkgs.procps}/bin/pgrep -f 'share/herdr/plugins/smart-rename/src/worker.ts' || true); do
        if ! ${pkgs.coreutils}/bin/tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null \
          | ${pkgs.gnugrep}/bin/grep -qF "${smartRename}/share/herdr/plugins/smart-rename"; then
          run ${pkgs.coreutils}/bin/kill "$pid"
        fi
      done
      rename_config=$(${herdr} plugin config-dir tab-smart-rename)
      if [ -s "$rename_config/model-selection.json" ]; then
        run ${herdr} plugin action invoke start --plugin tab-smart-rename
      fi
    '';
  };

  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [theme]
    name = "terminal"
    auto_switch = false

    [ui]
    status_indicators = "symbols"
    agent_panel_sort = "priority"
    prompt_new_tab_name = false

    [ui.toast]
    delivery = "system"
    delay_seconds = 1

    [update]
    version_check = false

    [keys]
    # Direct shortcuts; defaults for each overridden key are kept alongside.
    new_tab = ["alt+enter", "prefix+c"]
    new_workspace = ["alt+n", "prefix+shift+n"]
    close_tab = ["alt+x", "prefix+shift+x"]
    close_workspace = ["alt+q", "prefix+shift+d"]
    switch_tab = ["prefix+1..9", "alt+1..9"]
    switch_workspace = "alt+shift+1..9"

    [[keys.command]]
    key = "prefix+r"
    type = "plugin_action"
    command = "tab-smart-rename.rename-now"
    description = "Name this tab from its current task"
  '';
}
