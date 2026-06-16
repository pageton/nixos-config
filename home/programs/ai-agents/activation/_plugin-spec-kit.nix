# github/spec-kit slash command installation for Claude Code, Codex, and OpenCode.
#
# Mirrors spec-kit's MarkdownIntegration.setup() + process_template():
#   - git-clones github/spec-kit
#   - processes templates/commands/*.md (substitutes {SCRIPT},
#     __SPECKIT_COMMAND_<NAME>__, __CONTEXT_FILE__, rewrites script paths)
#   - writes speckit.<name>.md into every OpenCode profile's commands dir
#   - writes speckit-<name>.md into Claude Code and Codex command dirs
#
# Commands reference .specify/scripts/bash/setup-*.sh which the `specify`
# CLI (installed via services.nix) bootstraps per-project.

{
  cfg,
  pkgs,
  lib,
  opencodeProfileNames,
}:

let
  speckitCfg = cfg.speckit;
  gitCloneUpdate = import ../helpers/_git-clone-update.nix { inherit pkgs; };
in
{
  installSpecKit = lib.mkIf speckitCfg.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${gitCloneUpdate {
        name = "spec-kit";
        url = "https://github.com/github/spec-kit.git";
      }}
      SPECKIT_DIR="$HOME/.local/share/spec-kit"

      # Process a raw spec-kit command template into agent-ready markdown.
      # Replicates the critical substitutions from
      # specify_cli.integrations.base.MarkdownIntegration.process_template()
      # without the cosmetic frontmatter scripts-block stripping (harmless
      # to leave in — OpenCode ignores unknown frontmatter keys).
      #
      # $1 = source file, $2 = command prefix (e.g. "/speckit." or "/speckit-")
      process_speckit_command() {
        local src="$1"
        local cmd_prefix="$2"

        # 1. Extract scripts.sh: value from YAML frontmatter
        local script_cmd
        script_cmd=$(${pkgs.gawk}/bin/awk '
          /^scripts:[[:space:]]*$/ { s=1; next }
          s && /^[^[:space:]#]/ { s=0 }
          s && /^[[:space:]]*sh:[[:space:]]*/ {
            sub(/^[[:space:]]*sh:[[:space:]]*/, "")
            gsub(/\r/, "")
            print; exit
          }
        ' "$src")

        local content
        content=$(cat "$src")

        # 2. Replace {SCRIPT} with the extracted script command
        if [[ -n "$script_cmd" ]]; then
          content="''${content//\{SCRIPT\}/$script_cmd}"
        fi

        # 3. Rewrite script paths: scripts/bash/ -> .specify/scripts/bash/
        #    specify CLI installs scripts into .specify/scripts/ per-project
        content="''${content//scripts\/bash\//.specify\/scripts\/bash\/}"
        content="''${content//scripts\/powershell\//.specify\/scripts\/powershell\/}"

        # 4. Replace __CONTEXT_FILE__ (opencode uses AGENTS.md)
        content="''${content//__CONTEXT_FILE__/AGENTS.md}"

        # 5. Replace __SPECKIT_COMMAND_<NAME>__ with cmd_prefix + <name>
        printf '%s' "$content" | ${pkgs.gnused}/bin/sed \
          -e "s|__SPECKIT_COMMAND_ANALYZE__|''${cmd_prefix}analyze|g" \
          -e "s|__SPECKIT_COMMAND_CHECKLIST__|''${cmd_prefix}checklist|g" \
          -e "s|__SPECKIT_COMMAND_CLARIFY__|''${cmd_prefix}clarify|g" \
          -e "s|__SPECKIT_COMMAND_CONSTITUTION__|''${cmd_prefix}constitution|g" \
          -e "s|__SPECKIT_COMMAND_IMPLEMENT__|''${cmd_prefix}implement|g" \
          -e "s|__SPECKIT_COMMAND_PLAN__|''${cmd_prefix}plan|g" \
          -e "s|__SPECKIT_COMMAND_SPECIFY__|''${cmd_prefix}specify|g" \
          -e "s|__SPECKIT_COMMAND_TASKS__|''${cmd_prefix}tasks|g" \
          -e "s|__SPECKIT_COMMAND_TASKSTOISSUES__|''${cmd_prefix}taskstoissues|g"
      }

      # === Claude Code ===
      if [[ -d "$SPECKIT_DIR/templates/commands" ]] && [[ "${
        if cfg.claude.enable then "1" else "0"
      }" == "1" ]] && [[ "${if speckitCfg.claude.enable then "1" else "0"}" == "1" ]]; then
        mkdir -p "$HOME/.claude/commands"
        ${lib.concatMapStringsSep "\n" (name: ''
          if [[ -f "$SPECKIT_DIR/templates/commands/${name}.md" ]]; then
            process_speckit_command "$SPECKIT_DIR/templates/commands/${name}.md" "/speckit-" \
              > "$HOME/.claude/commands/speckit-${name}.md"
          fi
        '') speckitCfg.claude.commands}
        echo "✓ Spec Kit installed for Claude Code"
      fi

      # === Codex ===
      if [[ -d "$SPECKIT_DIR/templates/commands" ]] && [[ "${
        if cfg.codex.enable then "1" else "0"
      }" == "1" ]] && [[ "${if speckitCfg.codex.enable then "1" else "0"}" == "1" ]]; then
        mkdir -p "$HOME/.codex/commands"
        ${lib.concatMapStringsSep "\n" (name: ''
          if [[ -f "$SPECKIT_DIR/templates/commands/${name}.md" ]]; then
            process_speckit_command "$SPECKIT_DIR/templates/commands/${name}.md" "/speckit-" \
              > "$HOME/.codex/commands/speckit-${name}.md"
          fi
        '') speckitCfg.codex.commands}
        echo "✓ Spec Kit installed for Codex"
      fi

      # === OpenCode ===
      if [[ -d "$SPECKIT_DIR/templates/commands" ]] && [[ "${
        if cfg.opencode.enable then "1" else "0"
      }" == "1" ]] && [[ "${if speckitCfg.opencode.enable then "1" else "0"}" == "1" ]]; then
        ${lib.optionalString speckitCfg.opencode.enable ''
          for profile in ${lib.concatStringsSep " " (map lib.escapeShellArg opencodeProfileNames)}; do
            commands_dir="$HOME/.config/$profile/commands"
            mkdir -p "$commands_dir"
            ${lib.concatMapStringsSep "\n" (name: ''
              if [[ -f "$SPECKIT_DIR/templates/commands/${name}.md" ]]; then
                process_speckit_command "$SPECKIT_DIR/templates/commands/${name}.md" "/speckit." \
                  > "$commands_dir/speckit.${name}.md"
              fi
            '') speckitCfg.opencode.commands}
          done
          echo "✓ Spec Kit installed for OpenCode"
        ''}
      fi
    ''
  );
}
