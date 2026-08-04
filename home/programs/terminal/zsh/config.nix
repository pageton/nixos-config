# Zsh core options, history, Oh My Zsh, plugins, keymap, and setOptions.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true; # Required: oh-my-zsh and /etc/zshrc call compinit; carapace adds completions on top via compdef
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Privacy-conscious history
    history = {
      size = 1000000;
      save = 1000000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true; # Remove duplicates first when trimming
      extended = true; # Save timestamps and durations
    };

    oh-my-zsh = {
      enable = true;
      theme = ""; # Starship handles the prompt

      plugins = [
        "sudo" # Double-ESC to prepend sudo
        "extract" # Universal archive extraction
        "copypath" # Copy current path to clipboard
        "copyfile" # Copy file contents to clipboard
        "bgnotify" # Notify on long-running commands
      ];
    };

    plugins = [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
    ];

    initContent = lib.mkAfter ''
      # Silence bgnotify D-Bus errors when notification daemon is unavailable
      __bgnotify_notifier() { notify-send "$1" "$2" 2>/dev/null || true; }
      bgnotify_threshold=5

      # Snappy vi mode (default 0.4s feels laggy)
      KEYTIMEOUT=1

      ZSH_AUTOSUGGEST_STRATEGY=("history" "completion")

      # Allow Orca to redefine omp as a function (conflicts with the omp alias)
      [[ -n "''${ORCA_OMP_STATUS_EXTENSION:-}" ]] && unalias omp 2>/dev/null

      # Suffix Aliases — open files by extension
      alias -s {nix,md,txt,json,yml,yaml,go,toml}=nvim
      alias -s {png,jpg,jpeg,gif,svg,pdf}=xdg-open

      # Global Aliases — pipe shortcuts usable anywhere in a command
      alias -g G="| grep"
      alias -g L="| less"
      alias -g H="| head"
      alias -g T="| tail"
      alias -g JQ="| jq"
      alias -g C="| wl-copy"
      alias -g NE="2>/dev/null"
      alias -g NUL=">/dev/null 2>&1"
    '';
    # Ensure NixOS system and Home-Manager profile bins are in PATH for ALL
    # shells, including non-interactive ones spawned by MCP servers and agents.
    # Without this, coreutils (tail, head, cut, etc.) are not found.
    # Also set ZSH_COMPDUMP early (in .zshenv) so that the compinit call in
    # /etc/zshrc uses the managed dump file location, preventing
    # "compdump: function definition file not found" errors.
    # The dump file is stamped with $ZSH_VERSION so each zsh upgrade gets its
    # own cache — a version bump can never leave a stale .zwc that triggers
    # "zwc file has wrong version (zsh-X.Y.Z)" recompile errors.
    envExtra = ''
      ZSH_COMPDUMP="${config.xdg.cacheHome}/zsh/.zcompdump-''${ZSH_VERSION}"
      mkdir -p "$(dirname "$ZSH_COMPDUMP")"

      case ":$PATH:" in
        *":/run/current-system/sw/bin:"*) ;;
        *) export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:$PATH" ;;
      esac
    '';

    defaultKeymap = "viins"; # Vi insert mode (hybrid vi/emacs)
    setOptions = [
      "GLOB_DOTS"
      "EXTENDED_GLOB"
      "AUTO_CD"
      "AUTO_PUSHD"
      "PUSHD_IGNORE_DUPS"
      "PUSHD_SILENT"
      "COMPLETE_IN_WORD"
      "ALWAYS_TO_END"
      "NO_BEEP"
      "CORRECT"
      "INTERACTIVE_COMMENTS"
      "MAGIC_EQUAL_SUBST"
      "NONOMATCH"
      "NOTIFY"
      "NUMERIC_GLOB_SORT"
      "PROMPT_SUBST"
      "HIST_FIND_NO_DUPS"
      "HIST_IGNORE_ALL_DUPS"
      "HIST_SAVE_NO_DUPS"
      "HIST_VERIFY"
      "SHARE_HISTORY"
    ];
  };
}
