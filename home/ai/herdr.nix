# Configure Herdr preferences, its Codex integration hook, and the runtime
# for that integration.

{ aiPackages, pkgs, ... }:

{
  # The bundled Codex SessionStart hook silently skips reporting without python3.
  home.packages = [ pkgs.python3 ];

  # nixos/modules/codex.nix registers this hook system-wide; deploy it from the
  # pinned herdr package so the script updates with herdr itself.
  home.file.".codex/herdr-agent-state.sh" = {
    source = "${aiPackages.herdr}/share/herdr/integrations/codex/herdr-agent-state.sh";
    executable = true;
    force = true;
  };

  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [theme]
    name = "terminal"
    auto_switch = false

    [ui]
    status_indicators = "symbols"
    agent_panel_sort = "priority"

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
  '';
}
