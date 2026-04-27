# User Packages

Declarative package lists split into categorized chunk files. Each chunk receives `{ pkgs, pkgsStable }` and returns a flat package list. All lists are concatenated into `home.packages` by `home.nix`.

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
| `linting.nix` | Linters and formatters |
| `system-monitoring.nix` | System monitoring tools |
| `productivity.nix` | Productivity applications |
| `cool.nix` | Miscellaneous/niche tools |

## Conventions

- Each file is a plain function `{ pkgs, pkgsStable }: [ ... ]` returning a package list
- Use `pkgsStable` for packages that need the stable nixpkgs channel
- Alphabetize packages within each list
- To add a category: create file → add to `chunks` list in `default.nix`

## Dependencies

- **Imported by**: `home/home.nix` → `core/user.nix` (consumes the aggregated list)
