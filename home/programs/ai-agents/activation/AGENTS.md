# AI Agents — Activation

Home Manager activation scripts that run after `writeBoundary`. Handle late-stage operations that cannot be pure Nix: secret injection, config file generation with merge semantics, skills bootstrap with state caching, and plugin installation with cleanup on disable.

Parent: `home-manager/modules/ai-agents/AGENTS.md`

---

## Files

| File                                  | Purpose                                                                                                                                                                                                                                                          |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `default.nix`                         | Aggregation hub: wires all activation DAG entries into `home.activation`                                                                                                                                                                                         |
| `secrets.nix`                         | Secret patching: injects Z.AI, OpenRouter, Context7, GitHub tokens + Pi API root/key via jq/sed. Antigravity targets `~/.gemini/config/mcp_config.json`                                                                                                          |
| `claude-setup.nix`                    | Generates `~/.claude/settings.json` and `~/.mcp.json` with jq merge for existing configs                                                                                                                                                                         |
| `codex-setup.nix`                     | Generates `~/.codex/config.toml` (no `[profiles]` tables), standalone `~/.codex/<name>.config.toml` profile layers, and `~/.codex/agents/*.toml` custom agents                                                                                                   |
| `antigravity-setup.nix`               | jq-merges managed settings into `~/.gemini/antigravity-cli/settings.json` and MCP servers into `~/.gemini/config/mcp_config.json`; removes legacy Gemini-layout settings                                                                                         |
| `omp-setup.nix`                       | yq-merges `mcp.enableProjectConfig: false` into omp's app-owned `~/.omp/agent/config.yml`                                                                                                                                                                        |
| `zcode-setup.nix`                     | jq-merges `cfg.zcode.providers` (models deep-merged per `mergeModels`, array-safe recursive merge) into `~/.zcode/v2/config.json` and `cfg.zcode.extraSettings` into `~/.zcode/v2/setting.json` (managed keys win) — both files are app-owned, never `home.file` |
| `herdr-setup.nix`                     | jq-merges the OpenCode V2 TUI plugin entry (`"./herdr-opencode"`) into the app-owned `~/.config/opencode/cli.json`, deferring until OpenCode has created it |
| `herdr-copilot-setup.nix`             | jq-merges the herdr SessionStart direct hook into Copilot's app-owned `~/.copilot/settings.json`; writes the file fresh when Copilot has not created it |
| `skills.nix`                          | Skills CLI bootstrap with retry, state caching (SHA256 skip), Claude-to-Codex/Pi mirroring                                                                                                                                                                       |
| `plugins.nix`                         | Plugin aggregation: imports impeccable, agency-agents, ECC installers + cleanup                                                                                                                                                                                  |
| `_plugin-impeccable.nix`              | Impeccable skill pack: git clone, bun build, copy to Claude/OpenCode skill dirs                                                                                                                                                                                  |
| `_plugin-agency-agents.nix`           | Agency agents: clone and copy division agent `.md` files to agent dirs                                                                                                                                                                                           |
| `_plugin-everything-claude-code.nix`  | ECC: clone, curated copy of skills/commands/agents to all profiles                                                                                                                                                                                               |
| `_cleanup-agency-agents.nix`          | Removes agency-agent files when disabled, preserves curated agents                                                                                                                                                                                               |
| `_cleanup-everything-claude-code.nix` | Removes ECC files from Claude/Codex/OpenCode when disabled                                                                                                                                                                                                       |

---

## Conventions

- **DAG ordering**: All entries use `lib.hm.dag.entryAfter [ "writeBoundary" ... ]`. `secrets.nix` also depends on `"linkGeneration"`, `"setupCodexConfig"`, `"setupClaudeConfig"`.
- **Real files, not symlinks**: `claude-setup.nix` checks `[[ ! -L ]]` and does jq merge for existing real files.
- **Best-effort with warnings**: `skills.nix` logs failures as warnings and continues activation.
- **State caching**: `skills.nix` computes SHA256 of desired skill state and skips reinstall if unchanged.
- **Curated vs. installed**: cleanup files preserve agents defined in `_file-templates.nix` while removing plugin-installed files.

---

## Gotchas

- `secrets.nix` placeholder strings (`__GITHUB_TOKEN_PLACEHOLDER__`, etc.) must match exactly what `files.nix` and model configs write.
- Pi models.json uses `__ZAI_API_ROOT__` and `__ZAI_API_KEY_FILE__` placeholders — patched by `secrets.nix` using `sed` (not jq walk filters) since the file is generated fresh each activation.
- `skills.nix` intentionally disables `~/.agents/skills` (moves to `.disabled-by-home-manager`) to prevent OpenCode duplicate-skill spam.
- `codex-setup.nix` deletes non-ECC custom agents on each activation (`find ... ! -name 'ecc-*.toml' -delete`). Profile files are tracked in `~/.codex/.hm-managed-profiles` so only previously-managed, now-removed profiles are deleted; user-created profiles survive.
- `antigravity-setup.nix` only removes `~/.gemini/settings.json` when it matches the Home-Manager signature (`policyPaths == ["$HOME/.gemini/policies"]`), never user-written settings.
- `claude-setup.nix` writes CLAUDE.md from `cfg.globalInstructions` — same content injected into Codex and OpenCode via their own paths.
- Plugin/cleanup files use relative imports (`../helpers/`) that assume stable directory structure.

---

## Dependencies

- `../helpers/_mcp-transforms.nix`, `../helpers/_settings-builders.nix`, `../helpers/_opencode-profiles.nix`, `../helpers/_zai-filters.nix`, `../helpers/_file-templates.nix`, `../helpers/_git-clone-update.nix`
- `constants` from flake for Z.AI URL resolution
