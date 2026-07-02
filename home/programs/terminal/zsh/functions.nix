# Zsh initContent: shell functions, environment setup, and sops-enabled agent wrappers.

{
  config,
  constants,
  lib,
  secretLoader,
  ...
}:

let
  inherit (secretLoader) loadSecretFn;
  zaiEnv = import ../../ai-agents/helpers/_zai-env.nix { inherit constants; };
  # Provider-prefixed model IDs (source of truth for mimo/agent wrappers).
  models = import ../../ai-agents/helpers/_models.nix;

  # Derive OpenCode wrapper functions from profile definitions.
  # Single source: home/programs/ai-agents/helpers/_opencode-profiles.nix.
  opencodeProfiles = import ../../ai-agents/helpers/_opencode-profiles.nix { inherit config; };

  simpleWrapperProfiles = builtins.filter (
    p: p.alias != "oc" && p.name != "opencode-openrouter"
  ) opencodeProfiles.profiles;

  profileSuffix = p: builtins.replaceStrings [ "opencode-" ] [ "" ] p.name;

  # Oh My Pi (omp) profile definitions for wrapper functions.
  ompProfiles = import ../../ai-agents/helpers/_omp-profiles.nix { inherit config; };

  # OMP: simple wrappers (excludes default "omp" which has no profile suffix).
  simpleOmpProfiles = builtins.filter (p: p.name != "omp") ompProfiles.profiles;

  ompProfileSuffix = p: builtins.replaceStrings [ "omp-" ] [ "" ] p.name;

  # Pi (badlogic/pi-mono) profile definitions for wrapper functions.
  piProfiles = import ../../ai-agents/helpers/_pi-profiles.nix { inherit config; };

  simplePiProfiles = builtins.filter (p: p.name != "pi") piProfiles.profiles;

  piProfileSuffix = p: builtins.replaceStrings [ "pi-" ] [ "" ] p.name;
in

{
  programs.zsh.initContent = ''
    # === LS_COLORS ===
    # Vivid LS_COLORS (cached)
    if command -v vivid >/dev/null 2>&1; then
      ls_colors_cache="$HOME/.cache/vivid-ls-colors"
      if [[ ! -f "$ls_colors_cache" ]]; then
        mkdir -p "$HOME/.cache"
        vivid generate ${constants.theme} > "$ls_colors_cache"
      fi
      export LS_COLORS="$(cat "$ls_colors_cache")"
    fi

    # === Sops secret loading ===
    ${loadSecretFn}

    _load_gemini_key() { _load_secret gemini_api_key; }
    _load_zai_key() { _load_secret zai_api_key; }
    _load_openrouter_key() { _load_secret openrouter_api_key; }
    _load_deepseek_key() { _load_secret deepseek_api_key; }
    _load_mimo_key() { _load_secret mimo_api_key; }

    # Export Gemini key for gemini CLI (non-fatal — CLI is optional)
    if _gemini_key="$(_load_gemini_key 2>/dev/null)" && [[ -n "$_gemini_key" ]]; then
      export GEMINI_API_KEY="$_gemini_key"
    fi

    # Export Z.AI key for omp models.yml resolution (non-fatal)
    if _zai_key_export="$(_load_zai_key 2>/dev/null)" && [[ -n "$_zai_key_export" ]]; then
      export ZAI_API_KEY="$_zai_key_export"
    fi

    # === AI agent wrappers ===
    _ai_tab_icon() {
      if [[ -n "''${ZELLIJ_MOBILE:-}" ]]; then
        return 0
      fi

      case "$1" in
        cl*|ocl*|hcl*) printf '\uf1b0 ' ;;                   #  Claude — cl, clu, clglm, ocl, hcl + all workflow suffixes
        oc*|locgpt*|mocgpt*|xocgpt*) printf '\ue7a4 ' ;;     #  OpenCode — oc, ocglm, ocgem, ocgpt, ocs, oczen + all workflow suffixes
        cx*|lcx*|mcx*|hcx*|xcx*) printf '\uf1c0 ' ;;         #  Codex — cx, lcx, mcx, hcx, xcx + all workflow suffixes
        ag*|gem*) printf '\uf529 ' ;;                          #  Antigravity — ag/gem + all workflow suffixes
        omp*) printf '\uf1b2 ' ;;                              #  OMP — omp, omps, ompop, ompglm, ompgem, ompgpt, ompor, ompzen + all workflow suffixes
        pi*) printf '\uf1b2 ' ;;                              #  Pi — pi, pis, piop, piglm, pigem, pigpt, pior, pizen + all workflow suffixes
        *) ;;
      esac
    }

    _zellij_rename_tab() {
      local tab_name="$1"
      [[ -n "$tab_name" && -n "${"ZELLIJ:-"}" ]] || return 0
      local icon
      icon="$(_ai_tab_icon "$tab_name")"
      command zellij action rename-tab "''${icon}''${tab_name}" >/dev/null 2>&1 || true
    }

    _ai_agent_exec() {
      local tab_name="$1"
      shift
      if [[ "$1" == "--" ]]; then
        shift
      fi
      _zellij_rename_tab "$tab_name"
      # Inject --debug-file for Claude Code sessions
      if [[ "$1" == "claude" ]]; then
        local debug_dir="''${AI_AGENT_LOG_DIR:-$HOME/.local/share/ai-agents/logs}"
        mkdir -p "$debug_dir"
        set -- "$@" "--debug-file" "$debug_dir/claude-debug-$(date +%Y-%m-%d).log"
      fi
      # Run under the ai-agents.slice to cap memory usage and prevent
      # the compositor/terminal from starving during large output.
      # Skip the slice for omp: its native Rust addon deadlocks under the
      # memory-constrained cgroup (hangs at startup with zero output, no OOM) —
      # run it directly, the same way bunx/omp_glm/omp_seek invoke it.
      # Also fall back to direct exec if systemd-run is unavailable, the
      # target is a shell function (systemd-run cannot resolve those),
      # or the transient scope already exists from a prior session.
      if [[ "$1" != "omp" ]] && command -v systemd-run >/dev/null 2>&1 && ! whence -w "$1" 2>/dev/null | grep -q 'function$'; then
        systemd-run --user --slice=ai-agents.slice --scope --unit="ai-''${tab_name}" -- "$@" 2>/dev/null || "$@"
      else
        "$@"
      fi
    }

    claude_glm() {
      local key; key="$(_load_zai_key)" || return 1
      _zellij_rename_tab "clglm"
      local debug_dir="''${AI_AGENT_LOG_DIR:-$HOME/.local/share/ai-agents/logs}"
      mkdir -p "$debug_dir"
      ANTHROPIC_AUTH_TOKEN="$key" \
      ${zaiEnv.inlinePrefix} \
      claude --dangerously-skip-permissions --debug-file "$debug_dir/claude-debug-$(date +%Y-%m-%d).log" "$@"
    }

    claude_seek() {
      local key; key="$(_load_deepseek_key)" || return 1
      _zellij_rename_tab "clsk"
      local debug_dir="''${AI_AGENT_LOG_DIR:-$HOME/.local/share/ai-agents/logs}"
      mkdir -p "$debug_dir"
      ANTHROPIC_AUTH_TOKEN="$key" \
      ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic" \
      ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]" \
      ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]" \
      ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash[1m]" \
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
      CLAUDE_CODE_EFFORT_LEVEL=max \
      claude --dangerously-skip-permissions --debug-file "$debug_dir/claude-debug-$(date +%Y-%m-%d).log" "$@"
    }

    claude_mimo() {
      local key; key="$(_load_mimo_key)" || return 1
      _zellij_rename_tab "clmi"
      local debug_dir="''${AI_AGENT_LOG_DIR:-$HOME/.local/share/ai-agents/logs}"
      mkdir -p "$debug_dir"
      ANTHROPIC_AUTH_TOKEN="$key" \
      ANTHROPIC_BASE_URL="https://token-plan-sgp.xiaomimimo.com/anthropic" \
      ANTHROPIC_DEFAULT_OPUS_MODEL="mimo-v2.5-pro[1m]" \
      ANTHROPIC_DEFAULT_SONNET_MODEL="mimo-v2.5-pro[1m]" \
      ANTHROPIC_DEFAULT_HAIKU_MODEL="mimo-v2.5[1m]" \
      claude --dangerously-skip-permissions --debug-file "$debug_dir/claude-debug-$(date +%Y-%m-%d).log" "$@"
    }

    omp_glm() {
      local key; key="$(_load_zai_key)" || return 1
      _zellij_rename_tab "opi"
      ZAI_API_KEY="$key" omp "$@"
    }

    omp_seek() {
      local key; key="$(_load_deepseek_key)" || return 1
      _zellij_rename_tab "ompds"
      DEEPSEEK_API_KEY="$key" omp "$@"
    }

    _opencode_profile() {
      local profile="$1"
      local tab_name="$2"
      shift 2
      _zellij_rename_tab "$tab_name"
      OPENCODE_CONFIG_DIR="$HOME/.config/opencode-$profile" opencode --log-level WARN "$@"
    }

    ${lib.concatStringsSep "\n\n" (
      map (p: ''
        opencode_${profileSuffix p}() {
          _opencode_profile "${profileSuffix p}" "${p.alias}" "$@"
        }
      '') simpleWrapperProfiles
    )}

    opencode_openrouter() {
      local key; key="$(_load_openrouter_key)" || return 1
      OPENROUTER_API_KEY="$key" _opencode_profile "openrouter" "ocor" "$@"
    }

    mimo_glm() {
      _zellij_rename_tab "miglm"
      mimo -m ${models.glm} "$@"
    }

    mimo_seek() {
      _zellij_rename_tab "miseek"
      mimo -m deepseek/deepseek-v4-pro "$@"
    }

    mimo_gpt() {
      _zellij_rename_tab "migpt"
      mimo -m openai/gpt-5.4 "$@"
    }

    za() {
      if [[ -n "''${ZELLIJ:-}" ]]; then
        zellij-ai-panel "$@"
      else
        zellij --layout ai
      fi
    }

    zac() {
      if [[ -n "''${ZELLIJ:-}" ]]; then
        if [[ -n "''${ZELLIJ_MOBILE:-}" ]]; then
          zellij action new-tab --name "council" --layout "$HOME/.config/zellij/layouts/ai-council.kdl"
        else
          zellij action new-tab --name "󰚩 council" --layout "$HOME/.config/zellij/layouts/ai-council.kdl"
        fi
      else
        zellij --layout ai-council
      fi
    }

    zalogs() {
      if [[ -n "''${ZELLIJ:-}" ]]; then
        if [[ -n "''${ZELLIJ_MOBILE:-}" ]]; then
          zellij action new-tab --name "ai-logs" --layout "$HOME/.config/zellij/layouts/ai-observe.kdl"
        else
          zellij action new-tab --name "󰙨 ai-logs" --layout "$HOME/.config/zellij/layouts/ai-observe.kdl"
        fi
      else
        zellij --layout ai-observe
      fi
    }

    zm() {
      zellij-mobile "$@"
    }

    zp() {
      if [[ -n "''${ZELLIJ:-}" ]]; then
        zellij action new-pane "$@"
      else
        echo "zp must be run inside Zellij" >&2
        return 1
      fi
    }

    zpr() {
      if [[ -n "''${ZELLIJ:-}" ]]; then
        zellij action new-pane --direction right "$@"
      else
        echo "zpr must be run inside Zellij" >&2
        return 1
      fi
    }

    zpd() {
      if [[ -n "''${ZELLIJ:-}" ]]; then
        zellij action new-pane --direction down "$@"
      else
        echo "zpd must be run inside Zellij" >&2
        return 1
      fi
    }


    # === AI multi-pane launcher ===
    # Launch multiple AI agents side-by-side in Zellij panes
    # Prompt injection: claude/codex use positional; opencode/Antigravity use --prompt
    aip() {
      if [[ $# -eq 0 ]]; then
        echo "Usage: aip <agent> [agent...] [\"prompt\"]" >&2
        echo "  Any alias or function: cl, clglm, oc, ocglm, ag, cx..." >&2
        echo "  Last arg becomes the initial prompt if not a known command." >&2
        echo "Examples:" >&2
        echo "  aip oc cl                  # Two agents side-by-side" >&2
        echo "  aip oc clglm ag            # Three agents" >&2
        echo '  aip oc ocglm "who are you" # With prompt injection' >&2
        return 1
      fi

      # Collect args into array for safe manipulation
      local -a agents=("$@")
      local prompt=""

      # Detect prompt: if last arg is not a recognized command, treat as prompt
      if ! type "''${agents[-1]}" &>/dev/null; then
        prompt="''${agents[-1]}"
        agents[-1]=()
      fi

      if [[ ''${#agents[@]} -eq 0 ]]; then
        echo "Error: no agents specified (only a prompt was given)" >&2
        return 1
      fi

      local layout_file zsh_bin
      layout_file=$(mktemp /tmp/aip-XXXXXX.kdl)
      zsh_bin="$SHELL"
      local joined_agents="''${(j:+:)agents}"

      # Escape double quotes for KDL string safety
      local kdl_prompt="''${prompt//\"/\\\"}"

      # Inherit zjstatus bar from default layout
      local default_layout="$HOME/.config/zellij/layouts/default.kdl"
      if [[ -f "$default_layout" ]]; then
        head -n -1 "$default_layout" > "$layout_file"
      else
        echo 'layout {' > "$layout_file"
      fi

      {
        echo "  tab name=\"$joined_agents\" focus=true {"
        echo '    pane split_direction="vertical" {'
        local i=0 cmd
        for agent in "''${agents[@]}"; do
          # Build command with prompt injection per agent family
          if [[ -n "$prompt" ]]; then
            case "$agent" in
              oc|ocglm|ocgem|ocgpt|ocor|ocs|oczen|opi|opencode*|ag|ag*|agy|antigravity*|gem*)
                cmd="$agent --prompt '$kdl_prompt'" ;;
              *)
                cmd="$agent '$kdl_prompt'" ;;
            esac
          else
            cmd="$agent"
          fi

          if [[ $i -eq 0 ]]; then
            echo "      pane name=\"$agent\" command=\"$zsh_bin\" focus=true {"
          else
            echo "      pane name=\"$agent\" command=\"$zsh_bin\" {"
          fi
          echo "        args \"-ic\" \"$cmd\""
          echo "      }"
          ((i++))
        done
        echo '    }'
        echo '  }'
        echo '}'
      } >> "$layout_file"

      if [[ -n "''${ZELLIJ:-}" ]]; then
        zellij action new-tab --layout "$layout_file"
      else
        zellij --layout "$layout_file"
      fi

      rm -f "$layout_file"
    }

    # === Zellij auto-rename tab ===
    if [[ -n "''${ZELLIJ:-}" ]]; then
      _zellij_tab_name_for_command() {
        local raw="$1"
        local cmd="''${raw%% *}"
        cmd="''${cmd:t}"
        case "$raw" in
          just\ check*) printf "󱓞 check" ;;
          just\ lint*) printf "󰁨 lint" ;;
          just\ test*) printf "󰙨 test" ;;
          just\ home*) printf "󱄅 home" ;;
          just\ nixos*) printf "󱄅 nixos" ;;
          just*) printf "just" ;;
          nix\ build*) printf "󱄅 nix build" ;;
          nix\ flake*) printf "󱄅 flake" ;;
          home-manager*) printf "󱄅 home" ;;
          nvim*|vim*|vi*) printf " edit" ;;
          lazygit*|git*) printf " git" ;;
          btop*|nvtop*|htop*) printf "󰍛 monitor" ;;
          docker*|podman*) printf "󰡨 containers" ;;
          pnpm\ dev*|npm\ run\ dev*|bun\ run\ dev*) printf "󰜎 dev" ;;
          pnpm*|npm*|bun*) printf "󰎙 js" ;;
          cargo\ test*) printf "󱘗 rs test" ;;
          cargo*) printf "󱘗 rust" ;;
          python*|uv*) printf " py" ;;
          cl*|claude*) printf "$(_ai_tab_icon cl)cl" ;;
          oc*|opencode*) printf "$(_ai_tab_icon oc)oc" ;;
          cx*|codex*) printf "$(_ai_tab_icon cx)cx" ;;
          gem*|gemini*) printf "$(_ai_tab_icon gem)gem" ;;
          za|zac|zalogs|aip*) printf "󰚩 ai" ;;
          *) printf "%s" "$cmd" ;;
        esac
      }

      _zellij_auto_tab_preexec() {
        local name
        name="$(_zellij_tab_name_for_command "$2")"
        case "$name" in
          cd|ls|ll|la|l|clear|cls|exit|source|\.|zellij|"") return 0 ;;
        esac
        command zellij action rename-tab "$name" >/dev/null 2>&1 || true
      }
      preexec_functions+=(_zellij_auto_tab_preexec)
    fi

    # === Environment setup ===
    export GPG_TTY=$(tty)

    if [ -f ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
      source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    fi

    for pydir in ~/.nix-profile/lib/python3.*/site-packages; do
      if [ -d "$pydir" ]; then
        export PYTHONPATH="$pydir:$PYTHONPATH"
        break
      fi
    done
  '';
}
