# Zellij terminal multiplexer.
{
  config,
  pkgs,
  ...
}: let
  inherit (config.lib.stylix) colors;

  # Kanagawa color aliases for zjstatus string interpolation
  bg = "#${colors.base00}"; # sumiInk1
  bg_alt = "#${colors.base01}"; # sumiInk0
  fg = "#${colors.base05}"; # fujiWhite
  comment = "#${colors.base03}"; # sumiInk6
  red = "#${colors.base08}"; # autumnRed
  orange = "#${colors.base09}"; # surimiOrange
  yellow = "#${colors.base0A}"; # boatYellow2
  green = "#${colors.base0B}"; # autumnGreen
  aqua = "#${colors.base0C}"; # waveAqua1
  blue = "#${colors.base0D}"; # crystalBlue
  purple = "#${colors.base0E}"; # oniViolet
  pink = "#${colors.base0F}"; # sakuraPink

  zjstatus = pkgs.fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm";
    hash = "sha256-3BmCogjCf2aHHmmBFFj7savbFeKGYv3bE2tXXWVkrho=";
  };
  zellij-autolock = pkgs.fetchurl {
    url = "https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm";
    hash = "sha256-aclWB7/ZfgddZ2KkT9vHA6gqPEkJ27vkOVLwIEh7jqQ=";
  };
  monocle = pkgs.fetchurl {
    url = "https://github.com/imsnif/monocle/releases/download/v0.100.2/monocle.wasm";
    hash = "sha256-TLfizJEtl1tOdVyT5E5/DeYu+SQKCaibc1SQz0cTeSw=";
  };
  room = pkgs.fetchurl {
    url = "https://github.com/rvcas/room/releases/download/v1.2.1/room.wasm";
    hash = "sha256-kLSDpAt2JGj7dYYhYFh6BfvtzVwTrcs+0jHwG/nActE=";
  };
  harpoon = pkgs.fetchurl {
    url = "https://github.com/Nacho114/harpoon/releases/download/v0.1.0/harpoon.wasm";
    hash = "sha256-ytn4faMd26q7mzbE1oINM/u62SXojxawa924K98AlgI=";
  };
  zellij-forgot = pkgs.fetchurl {
    url = "https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm";
    hash = "sha256-MRlBRVGdvcEoaFtFb5cDdDePoZ/J2nQvvkoyG6zkSds=";
  };
  multitask = pkgs.fetchurl {
    url = "https://github.com/leakec/multitask/releases/download/0.43.1/multitask.wasm";
    hash = "sha256-8IRkFe+JsBaAwGnFl0zOLJ5xsu1YGPhJY9LVPYg8VWA=";
  };

  zjstatusConfig = ''
    pane size=1 borderless=true {
      plugin location="file:~/.config/zellij/plugins/zjstatus.wasm" {
        format_left   "{mode}{tabs}"
        format_center ""
        format_right  "#[bg=${bg},fg=${bg_alt}]#[bg=${bg_alt},fg=${fg}]  {session} #[fg=${comment}]   {datetime} "
        format_space  "#[bg=${bg}]"
        format_hide_on_overlength "true"
        format_precedence "lrc"

        border_enabled  "false"

        hide_frame_for_single_pane "true"

        mode_normal        ""
        mode_locked        "#[bg=${yellow},fg=${bg_alt},bold]  LOCKED #[bg=${bg},fg=${yellow}]"
        mode_resize        "#[bg=${orange},fg=${bg_alt},bold] 󰩨 RESIZE #[bg=${bg},fg=${orange}]"
        mode_pane          "#[bg=${green},fg=${bg_alt},bold]  PANE #[bg=${bg},fg=${green}]"
        mode_tab           "#[bg=${blue},fg=${bg_alt},bold]  TAB #[bg=${bg},fg=${blue}]"
        mode_scroll        "#[bg=${aqua},fg=${bg_alt},bold]  SCROLL #[bg=${bg},fg=${aqua}]"
        mode_enter_search  "#[bg=${purple},fg=${bg_alt},bold]  SEARCH #[bg=${bg},fg=${purple}]"
        mode_search        "#[bg=${purple},fg=${bg_alt},bold]  SEARCH #[bg=${bg},fg=${purple}]"
        mode_rename_tab    "#[bg=${pink},fg=${bg_alt},bold] 󰑕 RENAME #[bg=${bg},fg=${pink}]"
        mode_rename_pane   "#[bg=${pink},fg=${bg_alt},bold] 󰑕 RENAME #[bg=${bg},fg=${pink}]"
        mode_session       "#[bg=${red},fg=${bg_alt},bold]  SESSION #[bg=${bg},fg=${red}]"
        mode_move          "#[bg=${yellow},fg=${bg_alt},bold] 󰆾 MOVE #[bg=${bg},fg=${yellow}]"
        mode_tmux          "#[bg=${aqua},fg=${bg_alt},bold]  TMUX #[bg=${bg},fg=${aqua}]"

        tab_normal              "#[bg=${bg_alt},fg=${comment}] {index}{floating_indicator}{fullscreen_indicator} #[bg=${bg},fg=${bg_alt}]"
        tab_active              "#[bg=${yellow},fg=${bg_alt},bold] {index}{floating_indicator}{fullscreen_indicator} #[bg=${bg},fg=${yellow}]"
        tab_separator           ""
        tab_floating_indicator  " 󰹙"
        tab_fullscreen_indicator " 󰊓"
        tab_sync_indicator      " "

        datetime          " {format} "
        datetime_format   "%H:%M  %d %b"
      }
    }
  '';
in {
  xdg.configFile = {
    # WASM plugins
    "zellij/plugins/zjstatus.wasm".source = zjstatus;
    "zellij/plugins/zellij-autolock.wasm".source = zellij-autolock;
    "zellij/plugins/monocle.wasm".source = monocle;
    "zellij/plugins/room.wasm".source = room;
    "zellij/plugins/harpoon.wasm".source = harpoon;
    "zellij/plugins/zellij-forgot.wasm".source = zellij-forgot;
    "zellij/plugins/multitask.wasm".source = multitask;

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
              pane name="git" command="lazygit"
            }
          }
        }

        tab name="servers" {
          pane name="server"
        }
      }
    '';

    "zellij/layouts/ai.kdl".text = ''
      layout {
        default_tab_template {
          children
          ${zjstatusConfig}
        }

        tab name="agent" focus=true {
          pane split_direction="vertical" {
            pane size="60%" name="claude" command="claude"
            pane split_direction="horizontal" {
              pane size="50%" name="logs" command="bash" {
                args "-c" "tail -f ~/.local/share/opencode/log/*.log ~/.codex/log/*.log 2>/dev/null || echo 'No agent logs yet. Waiting...'; sleep infinity"
              }
              pane name="git" command="lazygit"
            }
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
            pane command="btop"
            pane command="nvtop"
          }
        }

        tab name="logs" {
          pane name="journal" command="journalctl" {
            args "-f"
          }
        }
      }
    '';
  };

  programs.zellij = {
    enable = true;
    # HM's zellij attach -c breaks with multiple sessions; auto-start is in zsh initContent
    enableZshIntegration = false;

    settings = {
      theme = "default"; # Stylix generates ~/.config/zellij/themes/stylix.kdl defining "default"
      default_shell = "zsh";
      default_layout = "default";

      pane_frames = false;
      simplified_ui = false;
      styled_underlines = true;
      auto_layout = true;
      mouse_mode = true;

      copy_command = "${pkgs.wl-clipboard}/bin/wl-copy";
      copy_on_select = true;

      scroll_buffer_size = 50000;
      scrollback_editor = "nvim";

      session_serialization = true;
      pane_viewport_serialization = true;

      on_force_close = "detach";
      show_startup_tips = false;
      show_release_notes = false;
    };

    extraConfig = ''
      ui {
        pane_frames {
          rounded_corners true
          hide_session_name true
        }
      }

      plugins {
        autolock location="file:~/.config/zellij/plugins/zellij-autolock.wasm" {
          is_enabled true
          triggers "nvim|vim|git|fzf|zoxide|atuin|lazygit"
          reaction_seconds "0.9"
          print_to_log false
        }
      }

      load_plugins {
        autolock
      }

      keybinds {
        unbind "Ctrl q"

        scroll {
          bind "Esc" "q" { ScrollToBottom; SwitchToMode "Normal"; }
          bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
          bind "j" "Down" { ScrollDown; }
          bind "k" "Up" { ScrollUp; }
          bind "d" "Ctrl d" { HalfPageScrollDown; }
          bind "u" "Ctrl u" { HalfPageScrollUp; }
          bind "Ctrl f" "PageDown" { PageScrollDown; }
          bind "Ctrl b" "PageUp" { PageScrollUp; }
          bind "g" { ScrollToTop; }
          bind "G" { ScrollToBottom; }
          bind "y" { Copy; }
          bind "e" { EditScrollback; SwitchToMode "Normal"; }
          bind "/" "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
        }

        search {
          bind "Esc" "q" { ScrollToBottom; SwitchToMode "Normal"; }
          bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
          bind "j" "Down" { ScrollDown; }
          bind "k" "Up" { ScrollUp; }
          bind "d" "Ctrl d" { HalfPageScrollDown; }
          bind "u" "Ctrl u" { HalfPageScrollUp; }
          bind "Ctrl f" "PageDown" { PageScrollDown; }
          bind "Ctrl b" "PageUp" { PageScrollUp; }
          bind "n" { Search "down"; }
          bind "N" { Search "up"; }
          bind "c" { SearchToggleOption "CaseSensitivity"; }
          bind "w" { SearchToggleOption "Wrap"; }
          bind "o" { SearchToggleOption "WholeWord"; }
        }

        entersearch {
          bind "Ctrl c" "Esc" { SwitchToMode "Scroll"; }
          bind "Enter" { SwitchToMode "Search"; }
        }

        session {
          bind "Ctrl o" "Esc" { SwitchToMode "Normal"; }
          bind "d" { Detach; }
        }

        shared_except "scroll" "locked" "entersearch" "search" {
          bind "Ctrl s" { SwitchToMode "Scroll"; }
        }

        shared_except "locked" "renametab" "renamepane" "entersearch" {
          bind "Alt h" { MoveFocusOrTab "Left"; }
          bind "Alt j" { MoveFocus "Down"; }
          bind "Alt k" { MoveFocus "Up"; }
          bind "Alt l" { MoveFocusOrTab "Right"; }

          bind "Alt 1" { GoToTab 1; SwitchToMode "Normal"; }
          bind "Alt 2" { GoToTab 2; SwitchToMode "Normal"; }
          bind "Alt 3" { GoToTab 3; SwitchToMode "Normal"; }
          bind "Alt 4" { GoToTab 4; SwitchToMode "Normal"; }
          bind "Alt 5" { GoToTab 5; SwitchToMode "Normal"; }
          bind "Alt 6" { GoToTab 6; SwitchToMode "Normal"; }
          bind "Alt 7" { GoToTab 7; SwitchToMode "Normal"; }
          bind "Alt 8" { GoToTab 8; SwitchToMode "Normal"; }
          bind "Alt 9" { GoToTab 9; SwitchToMode "Normal"; }

          bind "Alt n" { NewPane; }
          bind "Alt s" { NewPane "Down"; SwitchToMode "Normal"; }
          bind "Alt v" { NewPane "Right"; SwitchToMode "Normal"; }
          bind "Alt x" { CloseFocus; SwitchToMode "Normal"; }
          bind "Alt z" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
          bind "Alt w" { ToggleFloatingPanes; SwitchToMode "Normal"; }
          bind "Alt f" { TogglePaneEmbedOrFloating; SwitchToMode "Normal"; }

          bind "Alt Enter" {
            NewTab {
              cwd "/home/sadiq"
            }
            SwitchToMode "Normal"
          }
          bind "Alt q" { CloseTab; SwitchToMode "Normal"; }
          bind "Alt 0" { ToggleTab; }
          bind "Alt ." { MoveTab "Right"; }
          bind "Alt ," { MoveTab "Left"; }

          bind "Alt =" { Resize "Increase"; }
          bind "Alt -" { Resize "Decrease"; }

          bind "Alt [" { PreviousSwapLayout; }
          bind "Alt ]" { NextSwapLayout; }

          bind "Alt e" { EditScrollback; SwitchToMode "Normal"; }

          bind "Alt o" {
            LaunchOrFocusPlugin "zellij:session-manager" {
              floating true
              move_to_focused_tab true
            }
          }

          bind "Alt p" {
            LaunchOrFocusPlugin "file:~/.config/zellij/plugins/monocle.wasm" {
              floating true
            }
          }
          bind "Alt r" {
            LaunchOrFocusPlugin "file:~/.config/zellij/plugins/room.wasm" {
              floating true
              ignore_case true
            }
          }
          bind "Alt b" {
            LaunchOrFocusPlugin "file:~/.config/zellij/plugins/harpoon.wasm" {
              floating true
            }
          }
          bind "Alt /" {
            LaunchOrFocusPlugin "file:~/.config/zellij/plugins/zellij-forgot.wasm" {
              floating true
              "LOAD_ZELLIJ_BINDINGS" "true"
            }
          }
          bind "Alt m" {
            LaunchPlugin "file:~/.config/zellij/plugins/multitask.wasm" {
              floating false
            }
          }
        }
      }
    '';
  };
}
