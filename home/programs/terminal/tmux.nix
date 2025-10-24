{ pkgsStable, ... }:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    escapeTime = 0;
    baseIndex = 1;
    prefix = "C-s";
    terminal = "tmux-256color";
    keyMode = "vi";
    historyLimit = 50000;

    extraConfig = ''
       set -as terminal-features ",alacritty*:RGB"

       # Make status bar stick to bottom and handle resizing properly
       set -g status-position bottom
       set -g aggressive-resize on
       set -g automatic-rename on
       set -g renumber-windows on

       # Better window resizing handling
       setw -g aggressive-resize on

       bind -n M-z resize-pane -Z  # Toggle pane zoom
       bind -n M-x confirm-before -p "kill-session #S? (y/n)" kill-session
       bind -n M-R command-prompt -I "#W" "rename-window '%%'"
       bind -n M-S command-prompt -I "#S" "rename-session '%%'"

       # Better copy mode
       bind -n M-[ copy-mode
       bind -T copy-mode-vi v send-keys -X begin-selection
       bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
       bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
       bind -T copy-mode-vi Escape send-keys -X cancel

       bind -n M-i source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

       bind C-p previous-window
       bind C-n next-window

       bind -n M-1 select-window -t 1
       bind -n M-2 select-window -t 2
       bind -n M-3 select-window -t 3
       bind -n M-4 select-window -t 4
       bind -n M-5 select-window -t 5
       bind -n M-6 select-window -t 6
       bind -n M-7 select-window -t 7
       bind -n M-8 select-window -t 8
       bind -n M-9 select-window -t 9

       bind -n M-Left select-pane -L
       bind -n M-Right select-pane -R
       bind -n M-Up select-pane -U
       bind -n M-Down select-pane -D

       bind -n M-H resize-pane -L 5
       bind -n M-L resize-pane -R 5
       bind -n M-K resize-pane -U 3
       bind -n M-J resize-pane -D 3

       bind -n M-s split-window -v
       bind -n M-v split-window -h

       bind -n M-f new-window -c ~/flake "nvim -c 'Telescope find_files' flake.nix"
       bind -n M-n new-window -c ~/.config/nvim "nvim -c 'Telescope find_files' init.lua"
       bind -n M-Enter new-window
       bind -n M-c kill-pane
       bind -n M-q kill-window
       bind -n M-Q kill-session

      # Status messages
       set -g display-time 2000
       set -g status-keys vi

       # Window activity
       setw -g monitor-activity on
       set -g visual-activity off
       set -g activity-action other
    '';

    plugins = with pkgsStable.tmuxPlugins; [
      # Session management and persistence
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-strategy-vim 'session'
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-processes 'ssh psql mysql sqlite3'
        '';
      }

      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
          set -g @continuum-boot 'on'
        '';
      }

      # Enhanced navigation
      {
        plugin = vim-tmux-navigator;
        extraConfig = ''
          # Smart pane switching with awareness of Vim splits
          set -g @vim_navigator_mapping_left "C-h"
          set -g @vim_navigator_mapping_down "C-j"
          set -g @vim_navigator_mapping_up "C-k"
          set -g @vim_navigator_mapping_right "C-l"
        '';
      }

      # Copy to system clipboard
      {
        plugin = yank;
        extraConfig = ''
          set -g @yank_selection_mouse 'clipboard'
          set -g @yank_action 'copy-pipe-no-clear'
        '';
      }

      # Better search
      {
        plugin = copycat;
        extraConfig = ''
          set -g @copycat_search_C-f 'C-f'
        '';
      }

      # Sensible defaults
      sensible
      vim-tmux-navigator
      tokyo-night-tmux
    ];
  };

  programs.zsh.initContent = ''
    if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
      tmux attach || tmux new
    fi
  '';
}
