{ config, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
  zjstatus = "${homeDir}/System/home/programs/zellij/plugins/zjstatus.wasm";
in
{
  imports = [
    ./bindings.nix
  ];
  home.file.".config/zellij/layouts/default.kdl" = {
    enable = true;
    source = ./layout.kdl;
    force = true;
  };
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    enableZshIntegration = true;
    settings = {
      show_startup_tips = false;
      ui.pane_frames.hide_session_name = true;
      pane_frames = false;
      mouse_mode = false;
      session_serialization = false;
      plugins.zjstatus.location = "file:${zjstatus}";
      themes = {
        default = {
          bg = "#585b70";
          fg = "#cdd6f4";
          red = "#f38ba8";
          green = "#a6e3a1";
          blue = "#89b4fa";
          yellow = "#f9e2af";
          magenta = "#f5c2e7";
          orange = "#fab387";
          cyan = "#89dceb";
          black = "#181825";
          white = "#cdd6f4";
        };
      };
      theme = "default";
    };
  };
}
