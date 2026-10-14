# Zellij settings and keybinds.
{
  config,
  constants,
  lib,
  pkgs,
  ...
}:

let
  enableAutolock = false;
  enableOtherPlugins = true;
in

{
  programs.zellij = {
    enable = true;
    # HM's zellij attach -c breaks with multiple sessions; auto-start is in zsh initContent
    enableZshIntegration = false;

    settings = {
      theme = "catppuccin-mocha-custom";
      default_shell = "${pkgs.zsh}/bin/zsh";
      default_layout = "default";
      default_cwd = config.home.homeDirectory;
      default_mode = "normal";
      layout_dir = "${config.home.homeDirectory}/.config/zellij/layouts";
      # The custom theme is defined inline in extraConfig's themes block below;
      # no external theme_dir exists, and Zellij errors on a missing one.

      pane_frames = false;
      simplified_ui = false;
      styled_underlines = true;
      auto_layout = true;
      mouse_mode = true;
      advanced_mouse_actions = false;
      mouse_hover_effects = false;
      focus_follows_mouse = false;
      visual_bell = false;

      copy_command = "${pkgs.wl-clipboard}/bin/wl-copy";
      copy_clipboard = "system";
      copy_on_select = true;

      scroll_buffer_size = 50000;
      scrollback_editor = "nvim";

      session_serialization = true;
      pane_viewport_serialization = true;
      scrollback_lines_to_serialize = 10000;
      serialization_interval = 120;

      on_force_close = "quit";
      show_startup_tips = false;
      show_release_notes = false;
      stacked_resize = true;
    };

    extraConfig = ''
      ${lib.optionalString enableAutolock ''
        plugins {
          autolock location="file:~/.config/zellij/plugins/zellij-autolock.wasm" {
            is_enabled true
            triggers "nvim|vim|git|fzf|zoxide|atuin|lazygit"
            reaction_seconds "0.3"
          }
        }

        load_plugins {
          autolock
        }
      ''}

      ${lib.optionalString enableOtherPlugins ''
        load_plugins {
          "file:~/.config/zellij/plugins/zellij-attention.wasm"
        }
      ''}

      themes {
        catppuccin-mocha-custom {
          fg "#${config.lib.stylix.colors.base05}"
          bg "#${config.lib.stylix.colors.base01}"
          black "#${config.lib.stylix.colors.base03}"
          red "#${config.lib.stylix.colors.base08}"
          green "${constants.color.blue_dim}"
          yellow "#${config.lib.stylix.colors.base0A}"
          blue "#${config.lib.stylix.colors.base0D}"
          magenta "#${config.lib.stylix.colors.base0E}"
          cyan "#${config.lib.stylix.colors.base0C}"
          white "#${config.lib.stylix.colors.base07}"
          orange "#${config.lib.stylix.colors.base09}"
        }
      }

      ui {
        pane_frames {
          rounded_corners true
          hide_session_name true
        }
      }

      keybinds {
        unbind "Ctrl q"
        unbind "Ctrl h"

        normal {
          unbind "Ctrl h"
          unbind "Ctrl j"
          unbind "Ctrl k"
          unbind "Ctrl l"
        }

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
          bind "Alt h" "Alt Left" { MoveFocus "Left"; }
          bind "Alt j" "Alt Down" { MoveFocus "Down"; }
          bind "Alt k" "Alt Up" { MoveFocus "Up"; }
          bind "Alt l" "Alt Right" { MoveFocus "Right"; }

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
          bind "Alt v" { NewPane "Right"; SwitchToMode "Normal"; MoveFocus "Left"; }
          bind "Alt S" { NewPane "stacked"; SwitchToMode "Normal"; }
          bind "Alt x" { CloseFocus; GoToNextTab; SwitchToMode "Normal"; }
          bind "Alt z" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
          bind "Alt w" { ToggleFloatingPanes; SwitchToMode "Normal"; }
          bind "Alt f" { TogglePaneEmbedOrFloating; SwitchToMode "Normal"; }

          bind "Alt Enter" { NewTab; SwitchToMode "Normal"; }
          bind "Alt q" { CloseTab; SwitchToMode "Normal"; }
          bind "Alt 0" { ToggleTab; }
          bind "Alt ." { MoveTab "Right"; }
          bind "Alt ," { MoveTab "Left"; }

          bind "Alt =" { Resize "Increase"; }
          bind "Alt -" { Resize "Decrease"; }

          bind "Alt [" { PreviousSwapLayout; }
          bind "Alt ]" { NextSwapLayout; }

          bind "Alt e" { EditScrollback; SwitchToMode "Normal"; }

          ${lib.optionalString enableOtherPlugins ''
            bind "Alt o" {
              LaunchOrFocusPlugin "zellij:session-manager" {
                floating true
                move_to_focused_tab true
              }
            }
            bind "Alt O" {
              LaunchOrFocusPlugin "zellij:layout-manager" {
                floating true
                move_to_focused_tab true
              }
            }

            bind "Alt p" {
              LaunchOrFocusPlugin "file:~/.config/zellij/plugins/monocle.wasm" {
                floating true
              }
            }
            bind "Alt P" {
              LaunchOrFocusPlugin "zellij:plugin-manager" {
                floating true
                move_to_focused_tab true
              }
            }
            bind "Alt C" {
              LaunchOrFocusPlugin "configuration" {
                floating true
                move_to_focused_tab true
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
            bind "Alt g" {
              LaunchOrFocusPlugin "file:~/.config/zellij/plugins/zellij-worktree.wasm" {
                floating true
                move_to_focused_tab true
              }
            }
          ''}
        }
      }
    '';
  };
}
