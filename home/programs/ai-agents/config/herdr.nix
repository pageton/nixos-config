# herdr configuration via upstream home-manager module.
# Gated by programs.aiAgents.herdr.enable.

{ config, lib, ... }:

let
  aiCfg = config.programs.aiAgents;
in
{
  programs.herdr = lib.mkIf aiCfg.herdr.enable {
    enable = true;

    settings = {
      onboarding = false;

      theme.name = "catppuccin";

      ui = {
        show_agent_labels_on_pane_borders = true;
        agent_panel_scope = "current";
        sidebar_width = 32;
        mouse_capture = true;
      };

      ui.toast.delivery = "system";
      ui.sound.enabled = true;

      experimental.pane_history = true;
    };
  };
}
