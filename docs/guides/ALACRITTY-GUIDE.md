# Alacritty Terminal Guide

Alacritty is a GPU-accelerated terminal emulator with native Wayland support and fast performance. It's your primary terminal, typically launched with Zellij for session management.

---

## Launching Alacritty

From Niri:

| Key                  | What It Does                                 |
| -------------------- | -------------------------------------------- |
| `Super+Return`       | Open Alacritty with Zellij                   |
| `Super+Shift+Return` | Open Alacritty without Zellij                |
| `Super+T`            | Open scratchpad terminal (floating dropdown) |

From command line:

```bash
alacritty                    # Launch Alacritty
alacritty -e zsh             # Launch with specific shell
alacritty -t scratchpad      # Launch with custom title (for window rules)
```

---

## Keybindings

### Copy and Paste

| Key            | What It Does         |
| -------------- | -------------------- |
| `Ctrl+Shift+C` | Copy to clipboard    |
| `Ctrl+Shift+V` | Paste from clipboard |

Text is also automatically copied to clipboard when you select it with the mouse (`selection.save_to_clipboard` is enabled in config).

### Font Size

| Key      | What It Does               |
| -------- | -------------------------- |
| `Ctrl++` | Increase font size         |
| `Ctrl+-` | Decrease font size         |
| `Ctrl+0` | Reset font size to default |

### Scrolling

| Key              | What It Does               |
| ---------------- | -------------------------- |
| `Shift+PageUp`   | Scroll up one page         |
| `Shift+PageDown` | Scroll down one page       |
| `Shift+Home`     | Scroll to top of buffer    |
| `Shift+End`      | Scroll to bottom of buffer |

You can also scroll with the mouse wheel.

### Other

| Key            | What It Does                         |
| -------------- | ------------------------------------ |
| `Ctrl+Shift+N` | New window                           |
| `Ctrl+L`       | Clear screen (sends Ctrl+L to shell) |

### URLs

- **Ctrl+Click** on a URL to open it in your browser
- URLs are automatically detected and highlighted

---

## Configuration Highlights

Your Alacritty setup includes:

| Setting             | Value                           | Why                                  |
| ------------------- | ------------------------------- | ------------------------------------ |
| Font                | JetBrainsMono Nerd Font         | Ligatures, icons, code readability   |
| Font size           | System default (from constants) | Consistent with other apps           |
| Theme               | Gruvbox Dark                    | Managed by Stylix for consistency    |
| Cursor              | Block, blinking                 | Configured for visibility            |
| Scrollback          | 50,000 lines                    | Large buffer for log viewing         |
| Window padding      | 8px                             | Clean spacing                        |
| Window decorations  | Off                             | Niri handles decorations             |
| Copy on select      | Enabled                         | Select text to copy automatically    |
| Selection highlight | Inverted fg/bg                  | Clear visibility when selecting text |

---

## Mouse Features

| Action                    | What It Does                      |
| ------------------------- | --------------------------------- |
| Select text               | Copies to clipboard automatically |
| Ctrl+Click URL            | Opens URL in browser              |
| Scroll wheel              | Scroll through terminal output    |
| Mouse hidden while typing | Cleaner visual experience         |

---

## Tips

1. **Use Zellij for sessions.** Alacritty doesn't have built-in tabs/splits — that's what Zellij is for. `Super+Return` opens Alacritty with Zellij automatically.

2. **No close confirmation.** Alacritty won't ask to confirm close because Zellij handles session persistence. Your work is safe even if you close the terminal.

3. **Clipboard is bidirectional.** Apps can both read and write to your clipboard. This is convenient but be aware of security implications.

4. **GPU-accelerated rendering.** Alacritty uses the GPU for rendering via OpenGL/Vulkan, providing fast scrolling and low input latency.

---

## Configuration File

| File                                   | What It Controls                           |
| -------------------------------------- | ------------------------------------------ |
| `home/programs/terminal/alacritty.nix` | All Alacritty settings, keybindings, theme |

To apply changes after editing: `just home` (rebuilds Home Manager configuration).

---

## Quick Reference

| Key                 | Action               |
| ------------------- | -------------------- |
| `Ctrl+Shift+C`      | Copy                 |
| `Ctrl+Shift+V`      | Paste                |
| `Ctrl++` / `Ctrl+-` | Font size up/down    |
| `Ctrl+0`            | Reset font size      |
| `Shift+PageUp/Down` | Scroll page          |
| `Shift+Home/End`    | Scroll to top/bottom |
| `Ctrl+Shift+N`      | New window           |
| `Ctrl+Click`        | Open URL             |
