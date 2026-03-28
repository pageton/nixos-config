# Neovim Keybindings

`Leader` = `Space` | `LocalLeader` = `\` | Arrow keys are disabled in all modes.

---

### General

| Key | Mode | Description |
|-----|------|-------------|
| `jk` | i | Switch to Normal mode |
| `Ctrl-s` | n, i | Write current file |
| `Leader w` | n | Write current file |
| `Leader q` | n | Quit |
| `Leader nh` | n | Clear search highlight |
| `s` | n | Flash jump |
| `K` | n | LSP Hover |

### Navigation

| Key | Mode | Description |
|-----|------|-------------|
| `Ctrl-]` | n | Next buffer |
| `Ctrl-[` | n | Previous buffer |
| `Ctrl-h` | n | Tmux navigate left |
| `Ctrl-j` | n | Tmux navigate down |
| `Ctrl-k` | n | Tmux navigate up |
| `Ctrl-l` | n | Tmux navigate right |

### Insert Mode Navigation

| Key | Mode | Description |
|-----|------|-------------|
| `Ctrl-h` | i | Move cursor left |
| `Ctrl-j` | i | Move cursor down |
| `Ctrl-k` | i | Move cursor up |
| `Ctrl-l` | i | Move cursor right |

### Buffers

| Key | Mode | Description |
|-----|------|-------------|
| `Leader x` | n | Delete buffer |
| `Leader bc` | n | Pick buffer |
| `Leader bn` | n | Next buffer (bufferline) |
| `Leader bp` | n | Previous buffer (bufferline) |
| `Leader bmn` | n | Move buffer next |
| `Leader bmp` | n | Move buffer previous |
| `Leader bsd` | n | Sort buffers by directory |
| `Leader bse` | n | Sort buffers by extension |
| `Leader bsi` | n | Sort buffers by ID |

### Windows

| Key | Mode | Description |
|-----|------|-------------|
| `Leader ws` | n | Horizontal split |
| `Leader wv` | n | Vertical split |
| `Leader wd` | n | Close window |

### File Explorer and Picker

| Key | Mode | Description |
|-----|------|-------------|
| `Leader Space` | n | Smart find files |
| `Leader ,` | n | Buffers |
| `Leader /` | n | Grep |
| `Leader :` | n | Command history |
| `bb` | n | File explorer (Snacks) |
| `-` | n | Oil file manager |
| `Leader D` | n | Pick buffer diagnostics |

### Find

| Key | Mode | Description |
|-----|------|-------------|
| `Leader fb` | n | Buffers |
| `Leader fc` | n | Find config file |
| `Leader ff` | n | Find files |
| `Leader fg` | n | Find git files |
| `Leader fp` | n | Projects |
| `Leader fr` | n | Recent files |
| `Leader fn` | n | Notification history |
| `Leader fe` | n | Emoji / icons |

### Search / Grep

| Key | Mode | Description |
|-----|------|-------------|
| `Leader sb` | n | Buffer lines |
| `Leader st` | n | Search todos |
| `Leader sB` | n | Grep open buffers |
| `Leader sg` | n | Grep |
| `Leader sw` | n | Grep word / visual selection |
| `Leader sr` | n | Reset search highlight |

### LSP Navigation (Snacks Picker)

| Key | Mode | Description |
|-----|------|-------------|
| `gd` | n | Goto definition |
| `gD` | n | Goto declaration |
| `gr` | n | References (nowait) |
| `gI` | n | Goto implementation |
| `gy` | n | Goto type definition |
| `Leader ss` | n | LSP symbols |
| `Leader sS` | n | LSP workspace symbols |

### LSP Actions

| Key | Mode | Description |
|-----|------|-------------|
| `Leader la` | n | Code action |
| `Leader ln` | n | Rename symbol |
| `Leader lf` | n | Format |
| `Leader lh` | n | Hover |
| `Leader ls` | n | Signature help |
| `Leader le` | n | Open diagnostic float |
| `Leader ltf` | n | Toggle format on save |
| `Leader e` | n | Show diagnostics (float) |
| `Leader rs` | n | Restart LSP |

### LSP Goto (NVF built-in)

| Key | Mode | Description |
|-----|------|-------------|
| `Leader lgd` | n | Go to definition |
| `Leader lgD` | n | Go to declaration |
| `Leader lgt` | n | Go to type definition |
| `Leader lgi` | n | List implementations |
| `Leader lgr` | n | List references |
| `Leader lgn` | n | Next diagnostic |
| `Leader lgp` | n | Previous diagnostic |

### LSP Workspace

| Key | Mode | Description |
|-----|------|-------------|
| `Leader lwa` | n | Add workspace folder |
| `Leader lwr` | n | Remove workspace folder |
| `Leader lwl` | n | List workspace folders |
| `Leader lws` | n | Workspace symbols |
| `Leader lH` | n | Document highlight |
| `Leader lS` | n | Document symbols |

### Lspsaga Commands

Not bound to keys by default. Use command mode:

| Command | Description |
|---------|-------------|
| `:Lspsaga rename` | Rename symbol (UI) |
| `:Lspsaga code_action` | Code action (UI) |
| `:Lspsaga hover_doc` | Hover documentation |
| `:Lspsaga peek_definition` | Peek definition |
| `:Lspsaga finder` | Find references/definitions |
| `:Lspsaga outline` | Symbol outline |
| `:Lspsaga diagnostic_jump_next` | Next diagnostic |
| `:Lspsaga diagnostic_jump_prev` | Previous diagnostic |

### Git (Picker)

| Key | Mode | Description |
|-----|------|-------------|
| `Leader gb` | n | Git branches |
| `Leader gL` | n | Git log |
| `Leader gs` | n | Git status |
| `Leader gS` | n | Git stash |
| `Leader gd` | n | Git diff (hunks) |
| `Leader gf` | n | Git log (current file) |
| `Leader gl` | n | Open lazygit |

### Git (Hunks)

| Key | Mode | Description |
|-----|------|-------------|
| `Leader hs` | n, v | Stage hunk |
| `Leader hu` | n | Undo stage hunk |
| `Leader hr` | n, v | Reset hunk |
| `Leader hS` | n | Stage buffer |
| `Leader hR` | n | Reset buffer |
| `Leader hP` | n | Preview hunk |
| `Leader hb` | n | Blame line (full) |
| `Leader hd` | n | Diff this |
| `Leader hD` | n | Diff project |
| `]c` | n | Next hunk |
| `[c` | n | Previous hunk |

### Git Conflict

| Key | Mode | Description |
|-----|------|-------------|
| `Leader co` | n | Choose ours |
| `Leader ct` | n | Choose theirs |
| `Leader cb` | n | Choose both |
| `Leader c0` | n | Choose none |
| `]x` | n | Next conflict |
| `[x` | n | Previous conflict |

### Git Toggles

| Key | Mode | Description |
|-----|------|-------------|
| `Leader tb` | n | Toggle current line blame |
| `Leader tD` | n | Toggle deleted lines |

### Todo

| Key | Mode | Description |
|-----|------|-------------|
| `Leader tdt` | n | Open todos in Trouble |
| `Leader tdq` | n | Open todos in quickfix |
| `Leader st` | n | Search todos (picker) |

### Comments

| Key | Mode | Description |
|-----|------|-------------|
| `Ctrl-/` | n | Toggle current line comment |
| `gc` | n | Toggle line comment (operator) |
| `gcc` | n | Toggle current line comment |
| `gbc` | n | Toggle current block comment |
| `gb` | n | Toggle block comment (operator) |
| `gc` | v | Comment selection (linewise) |
| `gb` | v | Comment selection (blockwise) |

### DAP / Debug

| Key | Mode | Description |
|-----|------|-------------|
| `Leader dc` | n | Continue |
| `Leader dR` | n | Restart |
| `Leader dq` | n | Terminate |
| `Leader d.` | n | Re-run last session |
| `Leader dr` | n | Toggle REPL |
| `Leader dh` | n | Hover (inspect) |
| `Leader db` | n | Toggle breakpoint |
| `Leader dgc` | n | Run to cursor |
| `Leader dgi` | n | Step into |
| `Leader dgo` | n | Step out |
| `Leader dgj` | n | Step over (next) |
| `Leader dgk` | n | Step back |
| `Leader dvo` | n | Go up stacktrace |
| `Leader dvi` | n | Go down stacktrace |

### Rust (LocalLeader = `\`)

| Key | Mode | Description |
|-----|------|-------------|
| `\rr` | n | Runnables |
| `\rp` | n | Parent module |
| `\rm` | n | Expand macro |
| `\rc` | n | Open Cargo.toml |
| `\rg` | n | Crate graph |
| `\rd` | n | Debuggables |

### Treesitter

| Key | Mode | Description |
|-----|------|-------------|
| `gnn` | n | Init incremental selection |
| `grn` | v | Increment selection by node |

### Completion (nvim-cmp)

| Key | Mode | Description |
|-----|------|-------------|
| `Shift-Tab` | i | Select previous item |
| `Tab` | i | Select next item |
| `Ctrl-b` | i | Scroll docs up |
| `Ctrl-f` | i | Scroll docs down |
| `Ctrl-e` | i | Abort completion |
| `Enter` | i | Confirm selection |

### AI Assistance

| Key | Mode | Description |
|-----|------|-------------|
| `Alt-Tab` | i | Accept NeoCodeium suggestion |

### UI Toggles

| Key | Mode | Description |
|-----|------|-------------|
| `Leader uw` | n | Toggle word wrap |
| `Leader ul` | n | Toggle linebreak |
| `Leader us` | n | Toggle spellcheck |
| `Leader uc` | n | Toggle cursorline |
| `Leader un` | n | Toggle line numbers |
| `Leader ur` | n | Toggle relative numbers |
| `Leader ut` | n | Show tabline |
| `Leader uT` | n | Hide tabline |

### Other

| Key | Mode | Description |
|-----|------|-------------|
| `Leader lo` | n | Activate Otter LSP (embedded code) |
| `AerialToggle` | cmd | Toggle Aerial outline |
