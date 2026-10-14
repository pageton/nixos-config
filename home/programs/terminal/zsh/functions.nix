# Zsh initContent: shell functions, environment setup, and Zellij helpers.

{ constants, ... }:

{
  programs.zsh.initContent = ''
    # === LS_COLORS ===
    # Vivid LS_COLORS (cached)
    if command -v vivid >/dev/null 2>&1; then
      ls_colors_cache="$HOME/.cache/vivid-ls-colors"
      if [[ ! -f "$ls_colors_cache" ]]; then
        mkdir -p "$HOME/.cache"
        vivid generate ${constants.theme.name} > "$ls_colors_cache"
      fi
      export LS_COLORS="$(cat "$ls_colors_cache")"
    fi

    # === Zellij helpers ===
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
          nvim*|vim*|vi*) printf " edit" ;;
          lazygit*|git*) printf " git" ;;
          btop*|nvtop*|htop*) printf "󰍛 monitor" ;;
          docker*|podman*) printf "󰡨 containers" ;;
          herdr*|hd) printf "󰆍 herdr" ;;
          pnpm\ dev*|npm\ run\ dev*|bun\ run\ dev*) printf "󰜎 dev" ;;
          pnpm*|npm*|bun*) printf "󰎙 js" ;;
          cargo\ test*) printf "󱘗 rs test" ;;
          cargo*) printf "󱘗 rust" ;;
          python*|uv*) printf " py" ;;
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

    # === SSH key upload ===
    # Usage: ssh-copy <ip> [user]  (defaults to root)
    ssh-copy() {
      local ip="$1"
      local user="''${2:-root}"
      if [[ -z "$ip" ]]; then
        echo "Usage: ssh-copy <ip> [user]" >&2
        return 1
      fi
      ssh-copy-id -i ~/.ssh/id_ed25519.pub "''${user}@''${ip}"
    }

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
