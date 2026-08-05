#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 0 ]]; then
  url="$1"
  case "$url" in
    ytmpv://*)
      # Custom YouTube-to-mpv protocol
      exec /home/__USER__/.local/bin/youtube-mpv "$url"
      ;;
  esac
fi

exec /run/current-system/sw/bin/xdg-open "$@"
