# AI Agents — Model Configs

Home Manager modules setting default values for `programs.aiAgents.*` options. Each file configures a specific AI agent tool's defaults — model selection, agent definitions, feature flags, settings, and tool configurations.

Parent: `home-manager/modules/ai-agents/AGENTS.md`

---

## Files

| File                   | Purpose                                                                                       |
| ---------------------- | --------------------------------------------------------------------------------------------- |
| `default.nix`          | Import hub: imports antigravity, codex, opencode, zcode                                 |
| `antigravity.nix`      | Antigravity CLI (agy): agy-native settings (`toolPermission`, `permissions.deny`)             |
| `codex.nix`            | Codex CLI: model (gpt-5.6-sol, reasoning high), profiles, custom agents, features             |
| `opencode.nix`         | OpenCode: model (claude-opus), RE agents, commands, LSP, permissions                          |
| `zcode.nix`            | ZCode: managed setting.json values (`extraSettings` defaults — memory, indexing, queue mode, tool grouping, auto-archive, update pin) |
| `_opencode-agents.nix` | Plain attrset: `yoloPermission` shared by OpenCode/MiMoCode agent definitions                 |
| `_opencode-lsp.nix`    | Plain attrset (not a module): LSP server definitions for 9 languages                          |
| `_mimo-*.nix`          | MiMoCode android-re/web-re agent definitions                                                  |
| `_opencode-*.nix`      | OpenCode android-re/web-re agents and command definitions                                     |

---

## Conventions

- All files are proper Home Manager modules except the `_*.nix` helpers (plain attrsets).
- Model references come from `../../helpers/_models.nix` — never hardcode model strings.
- `extraSettings` pattern for complex nested config that doesn't map to typed options.
- Placeholder pattern for secrets: `__OPENROUTER_API_KEY_PLACEHOLDER__` etc., patched during activation.
- Workflow prompts imported from `../../helpers/_workflow-prompts.nix`.

---

## Gotchas

- `antigravity.nix` writes agy-native keys only (`toolPermission`, `artifactReviewPolicy`, `enableTerminalSandbox`, `allowNonWorkspaceAccess`, `editorMode`, `permissions.deny`); the Gemini CLI schema (`general.defaultApprovalMode`, `security.auth`, `context.*`, `tools.sandbox`) is no longer read by agy.
- `codex.nix` profiles become standalone `~/.codex/<name>.config.toml` files at activation — never `[profiles.*]` tables (Codex ≥0.134 refuses `--profile` when they exist).
- `codex.nix` custom agents become standalone `~/.codex/agents/*.toml` files; inline `[agents.<name>]` tables only accept `description` + `config_file`.
- `codex.nix` sets `trustedProjects` to the System directory path from `config.home.homeDirectory`.
- `opencode.nix` imports `../../android-re/_prompt.nix` — creates a dependency on the `android-re/` directory.
- `_opencode-lsp.nix` is imported directly by `opencode.nix` as the `lsp` option value.

---

## Dependencies

- `../../helpers/_models.nix` (agent modules)
- `../../helpers/_workflow-prompts.nix` (opencode.nix)
- `../../helpers/_destructive-rules.nix` (antigravity.nix)
- `../../android-re/_prompt.nix` (opencode.nix)
