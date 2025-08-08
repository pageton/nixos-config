{ config, ... }:

{
  imports = [
    ./aliases.nix
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000; # Increased from 10k
      save = 50000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      extended = true; # Save timestamps
    };

    oh-my-zsh = {
      enable = true;
      custom = builtins.toString ./custom_omz_dir;
      theme = "oxide";

      plugins = [
        # Core functionality
        "git"
        "sudo"

        # Development tools
        "docker"
        "docker-compose"
        "rust"
        "golang"
        "node"
        "npm"
        "yarn"

        # System utilities
        "systemd"
        "tmux"
        "history-substring-search"

        # Enhanced navigation
        "extract" # Smart archive extraction
        "colored-man-pages" # Colorized man pages

        # Productivity
        "copypath" # Copy current path to clipboard
        "copyfile" # Copy file contents to clipboard
        "web-search" # Quick web searches
      ];
    };

    # Enhanced shell options
    defaultKeymap = "viins"; # Vi mode by default

    # Additional shell options
    localVariables = {
      # FZF configuration
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
      FZF_CTRL_T_COMMAND = "$FZF_DEFAULT_COMMAND";
      FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git";

      # Better colors for ls/eza (fallback if vivid fails)
      LS_COLORS = "di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33:cd=1;33:su=1;31:sg=1;31:tw=1;34:ow=1;34";

      # Development environment
      EDITOR = "code";
      VISUAL = "code";
      PAGER = "bat";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    };

    initContent = ''
      # Enhanced Zsh options
      setopt AUTO_CD              # cd by typing directory name if it's not a command
      setopt CORRECT              # auto correct mistakes
      setopt INTERACTIVE_COMMENTS # allow comments in interactive mode
      setopt MAGIC_EQUAL_SUBST    # enable filename expansion for arguments of the form 'anything=expression'
      setopt NONOMATCH            # hide error message if there is no match for the pattern
      setopt NOTIFY               # report the status of background jobs immediately
      setopt NUMERIC_GLOB_SORT    # sort filenames numerically when it makes sense
      setopt PROMPT_SUBST         # enable command substitution in prompt

      # History options
      setopt HIST_BEEP            # beep when accessing nonexistent history
      setopt HIST_EXPIRE_DUPS_FIRST # expire duplicate entries first when trimming history
      setopt HIST_FIND_NO_DUPS    # do not display a line previously found
      setopt HIST_IGNORE_ALL_DUPS # delete old recorded entry if new entry is a duplicate
      setopt HIST_IGNORE_DUPS     # don't record an entry that was just recorded again
      setopt HIST_IGNORE_SPACE    # don't record an entry starting with a space
      setopt HIST_SAVE_NO_DUPS    # don't write duplicate entries in the history file
      setopt HIST_VERIFY          # show command with history expansion to user before running it
      setopt INC_APPEND_HISTORY   # add commands to HISTFILE in order of execution
      setopt SHARE_HISTORY        # share command history data

      # Add NPM global packages to PATH
      export PATH="$HOME/.npm-global/bin:$PATH"

      # Add local bin to PATH
      export PATH="$HOME/.local/bin:$PATH"

      # Set up better colors with vivid if available
      if command -v vivid >/dev/null 2>&1; then
        export LS_COLORS="$(vivid generate gruvbox-dark-soft)"
      fi

      # Enhanced completion
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case insensitive tab completion
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}" # colored completion (different colors for dirs/files/etc)
      zstyle ':completion:*' rehash true # automatically find new executables in path
      zstyle ':completion:*' menu select # highlight menu selection

      # Speed up completions
      zstyle ':completion:*' accept-exact '*(N)'
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path ~/.zsh/cache

      # Useful functions
      # Extract archives
      extract() {
        if [ -f $1 ] ; then
          case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }

      # Create directory and cd into it
      mkcd() {
        mkdir -p "$1" && builtin cd "$1"
      }

      # Quick project switcher
      proj() {
        local project_dir="$HOME/Projects"
        if [ -z "$1" ]; then
          builtin cd "$project_dir"
        else
          builtin cd "$project_dir/$1"
        fi
      }

      # Git worktree helper
      git-worktree-helper() {
        if [ -z "$1" ]; then
          git worktree list
        else
          git worktree add "../$(basename $(pwd))-$1" "$1"
        fi
      }

      # Start Tmux automatically if not already running. No Tmux in TTY
      if [ -z "$TMUX" ] && [ -n "$DISPLAY" ]; then
        tmux attach-session -t default || tmux new-session -s default
      fi

      # Start UWSM
      if uwsm check may-start > /dev/null && uwsm select; then
        exec systemd-cat -t uwsm_start uwsm start default
      fi
    '';
  };
}
