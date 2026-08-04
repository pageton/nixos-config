# herdr configuration via the upstream home-manager module.
# Gated by programs.aiAgents.herdr.enable.
#
# home-manager master now ships programs.herdr, so the local option module was
# removed. Two things the local module provided are ported here:
#   - package: pkgs.herdr is not in nixpkgs yet, so pin the flake-input build
#   - zsh shell integration: herdr integration shell zsh snippet

{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  aiCfg = config.programs.aiAgents;
in
{
  programs.herdr = lib.mkIf aiCfg.herdr.enable {
    enable = true;

    package = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;

    settings = {
      onboarding = false;

      theme.name = "catppuccin";

      ui = {
        agent_panel_sort = "spaces";
        show_agent_labels_on_pane_borders = true;
        sidebar_width = 32;
        mouse_capture = true;
      };

      ui.toast.delivery = "system";
      ui.sound.enabled = true;

      experimental.pane_history = true;
    };
  };

  programs.zsh.initContent = lib.mkIf (aiCfg.herdr.enable && config.programs.zsh.enable) ''
    eval "$(herdr integration shell zsh 2>/dev/null || true)"
  '';
}
