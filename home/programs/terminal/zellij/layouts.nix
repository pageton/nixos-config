# Zellij layout definitions (default, dev, herdr, monitoring).
# deadnix false-positive: constants IS used in zjstatusConfig string interpolation.
# deadnix: hide
{ constants, pkgs, ... }:
let
  enableZjstatus = true;
  zjstatusConfig =
    if enableZjstatus then
      ''
        pane size=1 borderless=true {
          plugin location="file:~/.config/zellij/plugins/zjstatus.wasm" {
            format_left   "{mode}#[bg=${constants.color.bg0},fg=${constants.color.gray}]  {session} {command_git_branch}"
            format_center "{tabs}"
            format_right  "#[bg=${constants.color.bg0},fg=${constants.color.gray}] {datetime} "
            format_space  "#[bg=${constants.color.bg_soft}]"
            format_hide_on_overlength "true"
            format_precedence "lrc"

            border_enabled  "false"

            hide_frame_for_single_pane "false"

            mode_normal        ""
            mode_locked        "#[bg=${constants.color.yellow_dim},fg=${constants.color.bg_hard},bold]  LOCKED #[bg=${constants.color.bg_soft},fg=${constants.color.yellow_dim}]"
            mode_resize        "#[bg=${constants.color.orange},fg=${constants.color.bg_hard},bold] 󰩨 RESIZE #[bg=${constants.color.bg_soft},fg=${constants.color.orange}]"
            mode_pane          "#[bg=${constants.color.blue_dim},fg=${constants.color.bg_hard},bold]  PANE #[bg=${constants.color.bg_soft},fg=${constants.color.blue_dim}]"
            mode_tab           "#[bg=${constants.color.blue},fg=${constants.color.bg_hard},bold]  TAB #[bg=${constants.color.bg_soft},fg=${constants.color.blue}]"
            mode_scroll        "#[bg=${constants.color.aqua},fg=${constants.color.bg_hard},bold]  SCROLL #[bg=${constants.color.bg_soft},fg=${constants.color.aqua}]"
            mode_enter_search  "#[bg=${constants.color.purple},fg=${constants.color.bg_hard},bold]  SEARCH #[bg=${constants.color.bg_soft},fg=${constants.color.purple}]"
            mode_search        "#[bg=${constants.color.purple},fg=${constants.color.bg_hard},bold]  SEARCH #[bg=${constants.color.bg_soft},fg=${constants.color.purple}]"
            mode_rename_tab    "#[bg=${constants.color.purple_dim},fg=${constants.color.bg_hard},bold] 󰑕 RENAME #[bg=${constants.color.bg_soft},fg=${constants.color.purple_dim}]"
            mode_rename_pane   "#[bg=${constants.color.purple_dim},fg=${constants.color.bg_hard},bold] 󰑕 RENAME #[bg=${constants.color.bg_soft},fg=${constants.color.purple_dim}]"
            mode_session       "#[bg=${constants.color.red},fg=${constants.color.bg_hard},bold]  SESSION #[bg=${constants.color.bg_soft},fg=${constants.color.red}]"
            mode_move          "#[bg=${constants.color.yellow},fg=${constants.color.bg_hard},bold] 󰆾 MOVE #[bg=${constants.color.bg_soft},fg=${constants.color.yellow}]"
            mode_tmux          "#[bg=${constants.color.aqua_dim},fg=${constants.color.bg_hard},bold]  TMUX #[bg=${constants.color.bg_soft},fg=${constants.color.aqua_dim}]"

            tab_normal              "#[bg=${constants.color.bg0},fg=${constants.color.gray}] {index} "
            tab_active              "#[bg=${constants.color.yellow_dim},fg=${constants.color.bg_hard},bold] {index}:{name}{floating_indicator}{fullscreen_indicator} "
            tab_rename              "#[bg=${constants.color.purple_dim},fg=${constants.color.bg_hard},bold] {index}:{name} "
            tab_separator           "#[bg=${constants.color.bg_soft},fg=${constants.color.bg1}]│"
            tab_floating_indicator  " 󰹙"
            tab_fullscreen_indicator " 󰊓"
            tab_sync_indicator      " 󰓦"
            tab_display_count       "8"
            tab_truncate_start_format "#[bg=${constants.color.bg_soft},fg=${constants.color.gray}]‹+{count} "
            tab_truncate_end_format   "#[bg=${constants.color.bg_soft},fg=${constants.color.gray}] +{count}›"

            command_git_branch_command "bash -lc 'branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0; printf \" %s\" \"$branch\"'"
            command_git_branch_format "#[bg=${constants.color.bg0},fg=${constants.color.yellow_dim}] {stdout} "
            command_git_branch_interval "10"
            command_git_branch_rendermode "static"


            datetime          " {format} "
            datetime_timezone "Etc/GMT-3"
            datetime_format   "%I:%M %p  %d %b"
          }
        }
      ''
    else
      "";
in
{
  xdg.configFile = {
    "zellij/layouts/default.kdl".text = ''
      layout {
        default_tab_template {
          children
          ${zjstatusConfig}
        }
      }
    '';

    "zellij/layouts/dev.kdl".text = ''
      layout {
        default_tab_template {
          children
          ${zjstatusConfig}
        }

        tab name="code" focus=true {
          pane split_direction="vertical" {
            pane size="75%" command="nvim" focus=true
            pane split_direction="horizontal" size="25%" {
              pane name="shell"
              pane name="git" command="${pkgs.lazygit}/bin/lazygit"
            }
          }
        }

        tab name="servers" {
          pane name="server"
        }
      }
    '';

    "zellij/layouts/herdr.kdl".text = ''
      layout {
        default_tab_template {
          children
          ${zjstatusConfig}
        }

        tab name="herdr" focus=true {
          pane name="herdr" command="${pkgs.zsh}/bin/zsh" focus=true {
            args "-ic" "herdr"
          }
        }
      }
    '';

    "zellij/layouts/monitoring.kdl".text = ''
      layout {
        default_tab_template {
          children
          ${zjstatusConfig}
        }

        tab name="system" focus=true {
          pane split_direction="horizontal" {
            pane command="${pkgs.btop}/bin/btop"
            pane command="${pkgs.nvtopPackages.nvidia}/bin/nvtop"
          }
        }

        tab name="logs" {
          pane name="journal" command="/run/current-system/sw/bin/journalctl" {
            args "-f"
          }
        }
      }
    '';
  };
}
