# Desktop Application Wrappers

Desktop utility scripts for browser selection, media playback, XDG integration, and MCP tooling.

## Files

| File | Purpose |
|------|---------|
| `browser-select.sh` | Interactive fzf-based browser/profile selector |
| `youtube-mpv.sh` | Open YouTube URLs in mpv via clipboard or argument |
| `xdg-open-wrapper.sh` | XDG-open wrapper for Wayland URL/file handling |
| `playwright-cli-mcp-wrapper.sh` | MCP server wrapper for Playwright browser automation |
| `element-desktop-keyring.sh` | Element Desktop keyring/secret integration helper |

## Conventions

- Each script is standalone (`#!/usr/bin/env bash` + `set -euo pipefail`)
- Scripts integrate with Wayland/Niri desktop environment
- Browser-select works with Zen Browser multi-profile setup

## Dependencies

- **Sources**: `scripts/lib/logging.sh`, `scripts/lib/fzf-theme.sh`
- **Used by**: Desktop keybindings (niri bindings), XDG MIME handlers
