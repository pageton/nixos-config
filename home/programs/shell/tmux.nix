{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    escapeTime = 0;
    baseIndex = 1;
    shell = "${pkgs.zsh}/bin/zsh";
    prefix = "C-s";
    terminal = "kitty";
    keyMode = "vi";

    extraConfig = ''
      set -as terminal-features ",kitty*:RGB"

      # Make status bar stick to bottom and handle resizing properly
      set -g status-position bottom
      set -g aggressive-resize on
      set -g automatic-rename on
      set -g renumber-windows on

      # Better window resizing handling
      setw -g aggressive-resize on

      bind -n M-r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

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
    '';

    plugins = with pkgs; [
      tmuxPlugins.vim-tmux-navigator
      tmuxPlugins.sensible
      tmuxPlugins.tokyo-night-tmux
    ];
  };
}
