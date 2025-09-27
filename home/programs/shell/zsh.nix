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
      # FZF (fuzzy finder) configuration for better file/directory search
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git"; # Default file search command
      FZF_CTRL_T_COMMAND = "$FZF_DEFAULT_COMMAND"; # File search for Ctrl+T
      FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git"; # Directory search for Alt+C

      # Fallback LS_COLORS if vivid is not available
      LS_COLORS = "di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33:cd=1;33:su=1;31:sg=1;31:tw=1;34:ow=1;34";

      # Default applications for development
      EDITOR = "nvim"; # Default text editor
      PAGER = "bat"; # Default pager with syntax highlighting
      MANPAGER = "sh -c 'col -bx | bat -l man -p'"; # Enhanced man page viewer

      # Development environment variables
      LESS = "-R"; # Enable raw ANSI color codes in less
      LESSHISTFILE = "${config.xdg.cacheHome}/less/history"; # Less history file
      LESSHISTSIZE = "1000"; # Maximum lines in less history

      # Git configuration
      GIT_PAGER = "bat"; # Git pager with syntax highlighting

      # Python configuration
      PYTHONSTARTUP = "$HOME/.pythonrc"; # Python startup script
      PIP_CACHE_DIR = "${config.xdg.cacheHome}/pip"; # Pip cache directory
      UV_CACHE_DIR = "${config.xdg.cacheHome}/uv"; # uv cache directory
      UV_PYTHON_INSTALL_DIR = "${config.xdg.dataHome}/uv/python"; # uv Python installations

      # Node.js configuration
      NODE_REPL_HISTORY = "${config.xdg.dataHome}/node/node_repl_history"; # Node REPL history
      NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm"; # NPM cache directory
      YARN_CACHE_FOLDER = "${config.xdg.cacheHome}/yarn"; # Yarn cache directory

      # Go configuration
      CGO_ENABLED = "1"; # Enable CGO for Go
    };

    initContent = ''
      # Enhanced Zsh shell options for better user experience
      setopt AUTO_CD              # Auto-change to directory by typing its name
      setopt CORRECT              # Enable command auto-correction
      setopt INTERACTIVE_COMMENTS # Allow comments in interactive shell
      setopt MAGIC_EQUAL_SUBST    # Enable filename expansion for = expressions
      setopt NONOMATCH            # Hide "no match found" errors
      setopt NOTIFY               # Immediate background job status reports
      setopt NUMERIC_GLOB_SORT    # Sort filenames numerically when possible
      setopt PROMPT_SUBST         # Enable command substitution in prompts

      # Advanced history management options
      setopt HIST_BEEP            # Beep when accessing nonexistent history
      setopt HIST_EXPIRE_DUPS_FIRST # Remove duplicates first when trimming
      setopt HIST_FIND_NO_DUPS    # Don't display previously found lines
      setopt HIST_IGNORE_ALL_DUPS # Delete duplicate entries
      setopt HIST_IGNORE_DUPS     # Don't record consecutive duplicates
      setopt HIST_IGNORE_SPACE    # Don't record commands starting with space
      setopt HIST_SAVE_NO_DUPS    # Don't write duplicates to history file
      setopt HIST_VERIFY          # Show expanded command before execution
      setopt INC_APPEND_HISTORY   # Append commands in execution order
      setopt SHARE_HISTORY        # Share history across shell sessions

      # Extend PATH with additional directories
      export PATH="$HOME/.npm-global/bin:$PATH"  # NPM global packages
      export PATH="$HOME/.cache/.bun/bin:$PATH"  # Bun global packages
      export PATH="$HOME/.local/bin:$PATH"       # Local user binaries
      export PATH="$HOME/.cargo/bin:$PATH"       # Rust/Cargo binaries
      export PATH="$HOME/go/bin:$PATH"           # Go binaries
      export PATH="$HOME/.local/share/pnpm:$PATH" # pnpm global packages
      export PATH="$HOME/.deno/bin:$PATH"        # Deno binaries
      export PATH="$HOME/.config/composer/vendor/bin:$PATH" # PHP Composer
      export PATH="$HOME/.local/share/gem/ruby/3.1.0/bin:$PATH" # Ruby gems
      export PATH="$HOME/.local/share/uv/tools:$PATH" # uv tools
      export PATH="/usr/local/sbin:$PATH"        # System admin binaries
      export PATH="/usr/local/bin:$PATH"         # Additional system binaries

      # Development environment variables
      export GOPATH="$HOME/go"                   # Go workspace path
      export GOBIN="$HOME/go/bin"                # Go binary installation path
      export CARGO_HOME="$HOME/.cargo"           # Rust/Cargo home directory
      export RUSTUP_HOME="$HOME/.rustup"         # Rustup installation directory
      export PYENV_ROOT="$HOME/.pyenv"           # Python version manager
      export NVM_DIR="$HOME/.nvm"                # Node Version Manager
      export PNPM_HOME="$HOME/.local/share/pnpm" # pnpm home directory
      export BUN_INSTALL="$HOME/.bun"            # Bun installation directory
      export COMPOSER_HOME="$HOME/.config/composer" # PHP Composer home

      # XDG Base Directory specification
      export XDG_CONFIG_HOME="$HOME/.config"     # User config directory
      export XDG_CACHE_HOME="$HOME/.cache"       # User cache directory
      export XDG_DATA_HOME="$HOME/.local/share"  # User data directory
      export XDG_STATE_HOME="$HOME/.local/state" # User state directory

      # Language and locale settings
      export LANG="en_US.UTF-8"                  # Default language
      export LC_ALL="en_US.UTF-8"                # All locale categories
      export LC_CTYPE="en_US.UTF-8"              # Character classification

      # Development tool configurations
      export DOCKER_BUILDKIT=1                   # Enable BuildKit for Docker
      export COMPOSE_DOCKER_CLI_BUILD=1          # Use BuildKit with Docker Compose
      export DOTNET_CLI_TELEMETRY_OPTOUT=1       # Disable .NET telemetry
      export NEXT_TELEMETRY_DISABLED=1           # Disable Next.js telemetry

      # Enhanced color scheme using vivid (if available)
      if command -v vivid >/dev/null 2>&1; then
        export LS_COLORS="$(vivid generate gruvbox-dark-soft)"  # Generate Gruvbox colors
      fi

      # Advanced completion system configuration
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'       # Case-insensitive completion
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"       # Colored completion lists
      zstyle ':completion:*' rehash true                              # Auto-rehash for new executables
      zstyle ':completion:*' menu select                              # Highlight menu selection

      # Performance optimizations for completion
      zstyle ':completion:*' accept-exact '*(N)'                      # Accept exact matches
      zstyle ':completion:*' use-cache on                             # Enable completion caching
      zstyle ':completion:*' cache-path ~/.zsh/cache                  # Cache directory

      # Custom utility functions for enhanced productivity

      # Smart archive extraction function
      extract() {
        if [ -f $1 ] ; then
          case $1 in
            *.tar.bz2)   tar xjf $1     ;;  # Extract bzip2 tarball
            *.tar.gz)    tar xzf $1     ;;  # Extract gzip tarball
            *.bz2)       bunzip2 $1     ;;  # Extract bzip2 file
            *.rar)       unrar e $1     ;;  # Extract RAR archive
            *.gz)        gunzip $1      ;;  # Extract gzip file
            *.tar)       tar xf $1      ;;  # Extract tarball
            *.tbz2)      tar xjf $1     ;;  # Extract tbz2
            *.tgz)       tar xzf $1     ;;  # Extract tgz
            *.zip)       unzip $1       ;;  # Extract ZIP archive
            *.Z)         uncompress $1  ;;  # Extract compressed file
            *.7z)        7z x $1        ;;  # Extract 7z archive
            *)     echo "'$1' cannot be extracted via extract()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }

      # Create directory and navigate to it
      mkcd() {
        mkdir -p "$1" && builtin cd "$1"  # Create dir and cd into it
      }

      # Quick project directory navigation
      proj() {
        local project_dir="$HOME/Projects"  # Default projects directory
        if [ -z "$1" ]; then
          builtin cd "$project_dir"         # Go to projects root
        else
          builtin cd "$project_dir/$1"      # Go to specific project
        fi
      }

      # Git worktree management helper
      git-worktree-helper() {
        if [ -z "$1" ]; then
          git worktree list                  # List existing worktrees
        else
          git worktree add "../$(basename $(pwd))-$1" "$1"  # Create new worktree
        fi
      }

      # Auto-start Tmux in graphical sessions (skip in TTY)
      if [ -z "$TMUX" ] && [ -n "$DISPLAY" ]; then
        tmux attach-session -t default || tmux new-session -s default  # Attach to existing or create new session
      fi

      # Initialize Universal Wayland Session Manager (UWSM)
      if uwsm check may-start > /dev/null && uwsm select; then
        exec systemd-cat -t uwsm_start uwsm start default  # Start UWSM with logging
      fi

      # Source Home Manager environment variables
      if [ -f ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
        source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
      fi

      # Add Home Manager Python packages to PYTHONPATH
      if [ -d ~/.nix-profile/lib/python3.13/site-packages ]; then
        export PYTHONPATH="$HOME/.nix-profile/lib/python3.13/site-packages:$PYTHONPATH"
      fi
    '';
  };
}
