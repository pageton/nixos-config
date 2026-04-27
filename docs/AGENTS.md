# Documentation

User guides for tools and AI agent setup, plus skill definitions for AI coding agents.

## Architecture

```
docs/
├── guides/        # User-facing guides
│   ├── AI-AGENTS-GUIDE.md
│   ├── ALACRITTY-GUIDE.md
│   ├── NEOVIM-GUIDE.md
│   ├── NIRI-GUIDE.md
│   ├── YAZI-GUIDE.md
│   └── ZELLIJ-GUIDE.md
└── skills/        # AI agent skill directories
    ├── nix/
    ├── nix-best-practices/
    ├── nix-flakes/
    ├── nixos-best-practices/
    └── shell/
```

## Conventions

- Guides are Markdown files with setup instructions, keybindings, and usage tips
- Skills are directories containing prompt templates for AI agents
- Skill directories are synced from GitHub via `just skills-sync`
