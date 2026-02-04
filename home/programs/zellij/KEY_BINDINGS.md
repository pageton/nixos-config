# Zellij Key Bindings

> Defaults are cleared. Only the bindings below are active.

## Mode Switching (from Normal)

| Key | Action |
|-----|--------|
| `Alt + n` | Enter **Resize** mode |
| `Alt + p` | Enter **Pane** mode |
| `Alt + h` | Enter **Move** mode |
| `Alt + t` | Enter **Tab** mode |
| `Alt + s` | Enter **Scroll** mode |
| `Alt + r` | Check/validate config (`zellij setup --check`) |
| `Alt + 1`-`9` | Go to Tab N |
| `Alt + Enter` | New Tab |
| `Alt + [` | Enter **Scroll** mode *(tmux-style)* |

## Resize Mode

| Key | Action |
|-----|--------|
| `Alt + n` / `Esc` | Back to Normal |
| `←` | Increase Left |
| `↓` | Increase Down |
| `↑` | Increase Up |
| `→` | Increase Right |
| `=` / `+` | Increase |
| `-` | Decrease |

## Pane Mode

| Key | Action |
|-----|--------|
| `Alt + p` / `Esc` | Back to Normal |
| `←` | Focus Left |
| `→` | Focus Right |
| `↓` | Focus Down |
| `↑` | Focus Up |
| `p` | Switch Focus |
| `n` | New Pane |
| `d` | New Pane Down |
| `r` | New Pane Right |
| `s` | New Pane Stacked |
| `x` | Close Pane |
| `w` | Toggle Floating Panes |
| `e` | Toggle Embed/Float |
| `i` | Toggle Pane Pinned |

## Move Mode

| Key | Action |
|-----|--------|
| `Alt + h` / `Esc` | Back to Normal |
| `n` / `Tab` | Move Pane |
| `p` | Move Pane Backwards |
| `←` | Move Left |
| `↓` | Move Down |
| `↑` | Move Up |
| `→` | Move Right |

## Tab Mode

| Key | Action |
|-----|--------|
| `Alt + t` / `Esc` | Back to Normal |
| `←` / `h` | Previous Tab |
| `→` / `l` | Next Tab |
| `1`-`9` | Go to Tab N |
| `n` | New Tab |
| `x` | Close Tab |

## Scroll Mode

| Key | Action |
|-----|--------|
| `Alt + s` / `Esc` | Back to Normal |
| `e` | Edit Scrollback |
| `↓` / `j` | Scroll Down |
| `↑` / `k` | Scroll Up |
| `d` | Half Page Down |
| `u` | Half Page Up |
| `g` | Scroll to Top |
| `G` | Scroll to Bottom |
