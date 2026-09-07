# AGENTS.md — NixOS System Flake

Declarative NixOS flake managing two hosts (`desktop`, `thinkpad`) with Home-Manager, SOPS-encrypted secrets, Niri Wayland compositor with the Noctalia shell, and a multi-agent AI orchestration layer (Claude Code, OpenCode ×7 profiles, Codex, Antigravity, MiMoCode, omp, ZCode). ~309 Nix files, ~86 shell scripts.

## Scoped AGENTS.md

Almost every directory carries its own `AGENTS.md` with local conventions (42 total). **Read the nearest scoped file before editing inside a directory.** Key entry points:

| Path                             | Covers                                                       |
| -------------------------------- | ------------------------------------------------------------ |
| `home/programs/ai-agents/`       | AI agent orchestration: options → config → helpers → files → activation → services |
| `nixos/modules/AGENTS.md`        | System module conventions and category layout                |
| `scripts/AGENTS.md` (+ subdirs)  | Shell tooling, shared libs, `*-test.sh` conventions          |
| `docs/guides/AI-AGENTS-GUIDE.md` | User-facing guide to the agent aliases and workflows         |

## Architecture

```
flake.nix                  # 14 inputs; makeSystem/makeHome factories; loops over hosts/_inventory.nix
hosts/_inventory.nix       # Host registry — add a host here + hosts/<name>/, flake picks it up
shared/constants.nix       # SSOT: user, fonts, colors, keyboard, ports, proxies — never hardcode these
nixos/modules/             # System modules: flat .nix files + category dirs (core, hardware, desktop,
                           #   network, security-stack, apps, virtualization, observability,
                           #   performance, maintenance, helpers), each with a default.nix import hub
hosts/<name>/              # Per-host configuration.nix + hardware config + ./modules overrides
home/                      # Home-Manager: core, packages, programs (ai-agents, terminal, nvf,
                           #   librewolf, languages, isolation), desktop (niri, noctalia), themes
scripts/                   # ai (agents + android-re/web-re RE toolkits), build (quality gates),
                           #   apps, hardware, inventory, lib, sops, system
inventory/                 # Server inventory (permanent/ + ephemeral/ are GITIGNORED — real IPs, never push)
secrets/secrets.yaml       # SOPS age-encrypted secrets
justfile                   # All task automation
```

Build pipeline: `hosts/_inventory.nix` → `flake.nix` → `nixosConfigurations.<host>` (imports `nixos/modules` + host `./modules`) and `homeConfigurations.<user>@<host>` → `home/home.nix` → core/programs/desktop/themes. `shared/constants.nix` reaches every module via `specialArgs.constants`.

Secrets flow: `secrets/secrets.yaml` → sops-nix decrypts at activation → `/run/secrets/<key>` (tmpfs) → consumed by services, scripts via `_load_secret()`, or `sops.placeholder.*`. AI-agent MCP keys are written as placeholders and jq-patched into configs at activation — real keys never enter the Nix store.

AI agents: `programs.aiAgents.*` options (`options.nix`) → values (`config/`) → shared logic (`helpers/`) → file declarations (`files.nix`) → activation-time secret/plugin/skill setup (`activation/`) → packages/services/aliases (`services.nix`). `config/global-instructions.md` is injected into every agent (Claude `~/.claude/CLAUDE.md`, OpenCode/MiMoCode `instructions`, Codex `developer_instructions`, Antigravity `systemInstruction`, omp `~/.omp/agent/AGENTS.md`, ZCode `~/.zcode/AGENTS.md`). Shared MCP servers are defined once in `programs.aiAgents.mcpServers` and transformed per-agent by `helpers/_mcp-transforms.nix` — never define them per-agent.

## Commands

```bash
just format      # nixfmt --strict on all .nix
just lint        # statix + shellcheck
just modules     # verify every .nix is imported by a default.nix (tree-wide)
just security    # risky-pattern and plaintext-secret scan
just check       # nix flake check (eval all outputs)
just eval-current# eval timing for the current host only
just qa-fast     # modules + security + eval-current in parallel (pre-commit parity)
just qa          # modules + security + check + eval-audit
just nixos       # nh os switch (current host); `just nixos <host>` to target
just home        # nh home switch
just install-hooks   # symlink repo pre-commit/pre-push hooks into .git/
just sops-edit   # edit secrets (decrypts to tmpfs only)
just secrets-add <key>  # add one secret (value from stdin)
```

Shell tests: `bash <script>-test.sh` next to the script under test. Docs: `just --list` for everything.

## Conventions

- **Module pattern**: every NixOS module exposes `mySystem.<module>.enable` for per-host opt-in; Home-Manager uses `programs.*`. Flat `.nix` modules live at `nixos/modules/` level and are imported by their category `default.nix`.
- **Import hubs**: `default.nix` is always the import hub; `_*.nix` files are plain helpers imported directly by consumers, never listed in hubs.
- **Formatting/lint**: `nixfmt --strict`, `statix`, `shellcheck` — all via `just`. Commits are GPG-signed with semantic prefixes (`feat:`, `fix:`, `chore:`, `refactor:`).
- **Scripts**: `#!/usr/bin/env bash` + `set -euo pipefail`; sourced libs in `scripts/lib/` omit `set -euo pipefail`.
- **Secrets**: never plaintext on disk, never in the Nix store, never in git. SOPS → `/run/secrets/` → `_load_secret()` or `sops.placeholder.*` only.
- **Constants**: check `shared/constants.nix` before hardcoding any port, path, font, color, or proxy.
- **New hosts**: append to `hosts/_inventory.nix`, create `hosts/<name>/configuration.nix` — done.

## Gotchas

1. **Niri flake input does NOT follow nixpkgs** — it pins its own mesa for GPU compatibility (see comment in `flake.nix`). Do not "fix" this.
2. **New `.nix` files must be `git add`-ed before `nix`/flake evals can see them** — path: flakes only see tracked files.
3. **CodeGraph daemon breaks nix evals** — while `codegraph serve` runs, `.codegraph/daemon.sock` makes every flake `path:` fetch fail ("unsupported type"), killing `just check`/`eval-*`/pre-commit. Stop it first: `kill "$(cat .codegraph/daemon.pid)" && rm -f .codegraph/daemon.sock`.
4. **Tree-wide import check** — `just modules` fails for any `.nix` module not referenced by a `default.nix`. Plain-imported helpers need a `# modules-check: manual-helper <files>` comment in their directory's `default.nix` (see `activation/default.nix` for the pattern).
5. **Cross-module assertions** — `nixos/modules/validation.nix` enforces mutual exclusions (TLP vs power-profiles-daemon, PipeWire vs PulseAudio, Mullvad vs DNSCrypt, firewall/AppArmor always-on). Check it before enabling conflicting modules.
6. **Python test overrides in flake.nix** — `picosvg`, `nanoemoji`, `gftools` carry `doCheck = false` (sandbox-incompatible font tests). Track upstream fixes.
7. **Android RE spoof sync** — `scripts/ai/android-re/_spoof-table.sh` and `frida-spoof-build.js` define the Pixel 7 spoof independently; change them together.
8. **`_agent-registry.sh` must be sourced AFTER `scripts/lib/logging.sh`** — it depends on logging functions.
9. **ZCode's config is app-owned** — `~/.zcode/v2/config.json` is rewritten by the running app; managed providers are jq-merged at activation (`activation/zcode-setup.nix`), never declared as `home.file`. Restart ZCode after activation.
10. **`inventory/permanent/` and `inventory/ephemeral/` are gitignored on purpose** (real IPs, force-added locally). Never commit, push, or inline their contents.
11. **Host deltas** — thinkpad has no gaming/virtualization/Mullvad; desktop has no Bluetooth/TLP/dGPU power modules. `result/` is a build artifact.
12. **Pre-commit hook** escalates modules → lint → format check → flake check, and hardcodes a deadnix exclude for the zellij `layouts.nix` (verify the path still matches if files move).

## Security

- Firewall (nftables) and AppArmor are asserted always-on; Mullvad runs lockdown mode with quantum-resistant keys (desktop); each browser profile gets a dedicated Mullvad SOCKS5 exit — never mix exits across profiles.
- `.gitignore` blocks key/material patterns (`.key`, `.pem`, `.p12`, `.env`, `id_rsa`, `id_ed25519`, `*-decrypted.*`); SOPS decrypted output only ever lives in `$XDG_RUNTIME_DIR` tmpfs.
- `just security` must stay clean — treat new findings as blockers, not noise.
