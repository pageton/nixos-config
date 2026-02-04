{ config, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
  zjstatus = "${homeDir}/System/home/programs/zellij/plugins/zjstatus.wasm";
in
{
  imports = [
    ./bindings.nix
  ];
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    enableZshIntegration = false; # Manual auto-start in zsh initContent (with WAYLAND_DISPLAY check)
    layouts.default = ''
      layout {
          pane {
              pane
          }

          pane size=1 borderless=true {
              plugin location="zjstatus" {
                  format_left  "{mode}#[fg=white,bg=blue,bold] :) #[fg=blue,bg=#181825]"
                  format_center "{tabs}"
                  format_right "#[fg=#181825,bg=#b1bbfa]{datetime}"
                  format_space "#[bg=#181825]"

                  mode_normal  "#[bg=blue] "

                  tab_normal              "#[fg=#181825,bg=#4C4C59] #[fg=#000000,bg=#4C4C59]{index} #[fg=#4C4C59,bg=#181825]"
                  tab_normal_fullscreen   "#[fg=#4b4e5d,bg=#181825] {index}"
                  tab_normal_sync         "#[fg=#4b4e5d,bg=#181825] {index}"
                  tab_active              "#[fg=#181825,bg=#ffffff,bold,italic] {index} #[fg=#ffffff,bg=#181825]"
                  tab_active_fullscreen   "#[fg=#9399B2,bg=#181825,bold,italic] {index}"
                  tab_active_sync         "#[fg=#9399B2,bg=#181825,bold,italic] {index}"

                  datetime          "#[fg=#4b4e5d,bg=#b1bbfa,bold] {format} "
                  datetime_format   "%A, %d %B/%m %Y %I:%M %p"
                  datetime_timezone "Asia/Baghdad"
              }
          }
      }
    '';
    settings = {
      show_startup_tips = false;
      ui.pane_frames.hide_session_name = true;
      pane_frames = false;
      mouse_mode = true;
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
