# User Packages

Declarative package lists split into categorized chunk files. Each chunk receives `{ pkgs, pkgsStable, constants }` and returns a flat package list. All lists are concatenated into `home.packages` by `home.nix`.

## Files

| File | Purpose |
|------|---------|
| `default.nix` | Aggregator: imports all chunks, flattens into single package list |
| `cli.nix` | Core CLI utilities (coreutils, curl, jq, ripgrep, etc.) |
| `applications.nix` | Desktop applications (browsers, editors, etc.) |
| `development.nix` | Development tools (compilers, debuggers, etc.) |
| `multimedia.nix` | Audio/video/image tools |
| `networking.nix` | Network utilities |
| `utilities.nix` | General-purpose utilities |
| `wayland.nix` | Wayland-specific tools (wl-clipboard, screenshot, etc.) |
| `privacy.nix` | Privacy and security tools |
| `system-monitoring.nix` | System monitoring tools |
| `productivity.nix` | Productivity applications |
| `cool.nix` | Miscellaneous/niche tools |
| `custom/` | Custom AppImage derivations (antigravity-cli, orca, t3code, tabby) |
## Directory Structure

```
home/packages/
├── default.nix    # Aggregator: imports all chunks
├── cli.nix        # Core CLI utilities
├── applications.nix # Desktop applications
├── development.nix # Development tools
├── multimedia.nix  # Audio/video/image tools
├── networking.nix  # Network utilities
├── utilities.nix   # General-purpose utilities
├── wayland.nix     # Wayland-specific tools
├── privacy.nix     # Privacy and security tools
├── system-monitoring.nix # System monitoring tools
├── productivity.nix # Productivity applications
├── custom/        # Custom AppImage derivations
└── cool.nix        # Miscellaneous/niche tools
```


## Conventions

- Each file is a plain function `{ pkgs, pkgsStable, constants }: [ ... ]` returning a package list
- Use `pkgsStable` for packages that need the stable nixpkgs channel
- `productivity.nix` uses `pkgs` (unstable) — its packages are not in pkgsStable
- Alphabetize packages within each list
- To add a category: create file → add to `chunks` list in `default.nix`

## Dependencies

- **Imported by**: `home/home.nix` → `core/user.nix` (consumes the aggregated list)
