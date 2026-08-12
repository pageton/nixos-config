# Skill installation activation script.
# Bootstraps skills CLI, installs configured skills with retry, manages state caching.
# Also mirrors installed skills to all OpenCode profiles.

{
  cfg,
  lib,
  pkgs,
  toJSON,
  opencodeProfileNames,
}:

let
  bunPackage = import ../../../_helpers/_bun-package.nix { inherit pkgs; };
  normalizedSkills = lib.unique cfg.skills;
  repoLevelSkills = builtins.filter builtins.isString normalizedSkills;
  individualSkills = builtins.filter (s: !(builtins.isString s)) normalizedSkills;
  individualSkillsByRepo = builtins.foldl' (
    acc: s: acc // { ${s.repo} = (acc.${s.repo} or [ ]) ++ [ s.skill ]; }
  ) { } individualSkills;
  desiredSkillStateJson = toJSON normalizedSkills;
  repoLevelSkillCommands = map (repo: ''
    repo_name=${lib.escapeShellArg repo}
    if grep -qxF "$repo_name" "$completed_file" 2>/dev/null; then
      echo "  [$((processed_groups + 1))/$configured_groups] $repo_name ⏭ already done"
      processed_groups=$((processed_groups + 1))
      skipped_installs=$((skipped_installs + 1))
    else
      processed_groups=$((processed_groups + 1))
      echo "  [$processed_groups/$configured_groups] $repo_name"
      echo "  → $repo_name"
      echo "  [AI] starting install for $repo_name at $(date +'%F %T')"
      total_attempts=$((total_attempts + 1))
      if install_repo_via_clone "$repo_name" ""; then
        echo "✔ Installed $repo_name"
        echo "$repo_name" >> "$completed_file"
        successful_installs=$((successful_installs + 1))
      else
        echo "❌ Failed to install $repo_name"
        failed_installs=$((failed_installs + 1))
      fi
    fi
  '') repoLevelSkills;
  individualSkillCommands = lib.mapAttrsToList (
    repo: skills:
    let
      uniqueSkills = lib.unique skills;
      skillList = lib.concatStringsSep ", " uniqueSkills;
    in
    ''
      repo_name=${lib.escapeShellArg repo}
      skill_list=${lib.escapeShellArg skillList}
      if grep -qxF "$repo_name" "$completed_file" 2>/dev/null; then
        echo "  [$((processed_groups + 1))/$configured_groups] $repo_name (${toString (builtins.length uniqueSkills)} skill(s)) ⏭ already done"
        processed_groups=$((processed_groups + 1))
        skipped_installs=$((skipped_installs + 1))
      else
        processed_groups=$((processed_groups + 1))
        echo "  [$processed_groups/$configured_groups] $repo_name (${toString (builtins.length uniqueSkills)} skill(s))"
        echo "  → $repo_name: $skill_list"
        echo "  [AI] starting install for $repo_name at $(date +'%F %T')"
        total_attempts=$((total_attempts + 1))
        if install_repo_via_clone "$repo_name" ""; then
          echo "✔ Installed $repo_name: $skill_list"
          echo "$repo_name" >> "$completed_file"
          successful_installs=$((successful_installs + 1))
        else
          echo "❌ Failed to install $repo_name: $skill_list"
          failed_installs=$((failed_installs + 1))
        fi
      fi
    ''
  ) individualSkillsByRepo;
  skillCommands = repoLevelSkillCommands ++ individualSkillCommands;
  installGroupCount =
    builtins.length repoLevelSkillCommands + builtins.length individualSkillCommands;
in
lib.mkIf true (
  lib.hm.dag.entryAfter [ "writeBoundary" "createJSWorkspace" ] ''
    export BUN_INSTALL="$HOME/.bun"
    export PATH="${pkgs.git}/bin:${bunPackage}/bin:$BUN_INSTALL/bin:$PATH"

    # skills CLI no longer used — clone+copy is the primary install method.
    # The CLI has unsuppressible interactive prompts, PromptScript blocking,
    # and missing --yes flag that make it unsuitable for batch activation.

    if ! command -v git >/dev/null 2>&1; then
      echo "❌ git is required for skills installation but is not in PATH"
      exit 1
    fi

    desired_skill_state_json=${lib.escapeShellArg desiredSkillStateJson}
    # Include a version marker so cache invalidates when install flags change
    desired_skill_state_hash=$(printf '%s:v7' "$desired_skill_state_json" | ${pkgs.coreutils}/bin/sha256sum | cut -d' ' -f1)
    skill_state_cache_dir="$HOME/.cache/ai-agents"
    skill_state_cache_file="$skill_state_cache_dir/skills-state.sha256"
    skill_lock_file="$HOME/.cache/ai-agents/skills-installed.marker"
    completed_file="$skill_state_cache_dir/skills-completed.txt"
    skip_skill_install=0

    if [[ -f "$skill_state_cache_file" ]] && [[ -f "$skill_lock_file" ]]; then
      current_skill_state_hash="$(cat "$skill_state_cache_file")"
      if [[ "$current_skill_state_hash" == "$desired_skill_state_hash" ]]; then
        echo "✓ Skills configuration unchanged; skipping reinstall"
        skip_skill_install=1
      fi
    fi
    if [[ "$skip_skill_install" -eq 0 ]]; then
      # Check if completed_file is for the current skill list (hash match)
      # vs stale from a different list that was cancelled.
      completed_hash_file="$skill_state_cache_dir/skills-completed.hash"
      if [[ -f "$completed_file" ]] && [[ -f "$completed_hash_file" ]]; then
        completed_list_hash="$(cat "$completed_hash_file")"
        if [[ "$completed_list_hash" == "$desired_skill_state_hash" ]]; then
          done_count=$(wc -l < "$completed_file" 2>/dev/null || echo 0)
          echo "📋 Resuming partial install ($done_count repo(s) already done)"
        else
          echo "🧹 Skill list changed — full reinstall"
          rm -rf "$HOME/.agents/skills"/* 2>/dev/null || true
          rm -rf "$HOME/.claude/skills"/* 2>/dev/null || true
          rm -f "$completed_file" "$completed_hash_file"
          echo "✓ Cleaned skill directories"
        fi
      else
        echo "🧹 Removing all existing global skills before reinstall..."
        rm -rf "$HOME/.agents/skills"/* 2>/dev/null || true
        rm -rf "$HOME/.claude/skills"/* 2>/dev/null || true
        rm -f "$completed_file" "$completed_hash_file"
        echo "✓ Cleaned skill directories"
      fi
      # Seed the completed_file tracking for this install run
      mkdir -p "$skill_state_cache_dir"
      printf '%s' "$desired_skill_state_hash" > "$completed_hash_file"
      : > "$completed_file"
      #   skills/<name>/SKILL.md  (most repos)
      #   .claude/skills/<name>/SKILL.md  (Claude plugin format)
      #   <name>/SKILL.md  (flat structure)
      install_repo_via_clone() {
        local repo="$1"
        local clone_dir
        clone_dir=$(mktemp -d)
        if ! git clone --depth 1 "https://github.com/''${repo}" "$clone_dir" 2>/dev/null; then
          rm -rf "$clone_dir"
          return 1
        fi
        local found=0
        local skill_src
        # Try common skill directory layouts
        for skill_src in "$clone_dir/skills" "$clone_dir/.claude/skills"; do
          if [[ -d "$skill_src" ]]; then
            cp -r "$skill_src"/* "$HOME/.claude/skills/" 2>/dev/null
            found=1
          fi
        done
        # Fallback: find any SKILL.md and copy its parent dir
        if [[ "$found" -eq 0 ]]; then
          for skill_md in $(find "$clone_dir" -name SKILL.md 2>/dev/null); do
            cp -r "$(dirname "$skill_md")" "$HOME/.claude/skills/" 2>/dev/null && found=1
          done
        fi
        rm -rf "$clone_dir"
        if [[ "$found" -eq 1 ]]; then
          return 0
        fi
        return 1
      }

      failed_installs=0
      successful_installs=0
      skipped_installs=0
      total_attempts=0
      processed_groups=0
      configured_entries=${toString (builtins.length normalizedSkills)}
      configured_groups=${toString installGroupCount}
      install_started_epoch=$(date +%s)
      echo "📦 Installing agent skills from skills.sh ($configured_entries configured entries, $configured_groups repo batch(es))..."
      echo "ℹ Running repo batches sequentially to avoid skills lock contention in global state"
      ${lib.concatStringsSep "" skillCommands}

      install_duration_seconds=$(( $(date +%s) - install_started_epoch ))
      if [[ "$failed_installs" -gt 0 ]]; then
        echo "⚠ Skills installation finished with $failed_installs failures"
        echo "⚠ $successful_installs succeeded — retrying remaining on next nh home switch"
      else
        mkdir -p "$skill_state_cache_dir"
        printf '%s' "$desired_skill_state_hash" > "$skill_state_cache_file"
        touch "$skill_lock_file"
        rm -f "$completed_file" "$completed_hash_file"
        echo "✓ Skills installation complete"
      fi
    fi

    # Mirror Claude skills to all agent skill directories.
    # skills.sh installs to ~/.claude/skills; we symlink into every other agent's skills dir.
    if [[ -d "$HOME/.claude/skills" ]]; then
      mirror_skills_to() {
        local target_dir="$1"
        mkdir -p "$target_dir"
        find "$target_dir" -maxdepth 1 -type l ! -exec test -e {} \; -delete 2>/dev/null || true
        shopt -s nullglob
        for skill_dir in "$HOME/.claude/skills"/*; do
          [[ -d "$skill_dir" ]] || continue
          skill_name="$(basename "$skill_dir")"
          link="$target_dir/$skill_name"
          if [[ ! -e "$link" ]]; then
            ln -sfn "$skill_dir" "$link"
          fi
        done
        shopt -u nullglob
      }

      mirror_count=0

      # OpenCode profiles
      for profile in ${lib.concatStringsSep " " (map lib.escapeShellArg opencodeProfileNames)}; do
        mirror_skills_to "$HOME/.config/$profile/skills"
        mirror_count=$((mirror_count + 1))
      done

      # Codex
      mirror_skills_to "$HOME/.codex/skills"
      mirror_count=$((mirror_count + 1))

      # Antigravity (agy reads from ~/.gemini/skills)
      mirror_skills_to "$HOME/.gemini/skills"
      mirror_count=$((mirror_count + 1))

      # Oh My Pi (omp) reads skills from ~/.omp/agent/skills
      mirror_skills_to "$HOME/.omp/agent/skills"
      mirror_count=$((mirror_count + 1))


      echo "✓ Mirrored skills to $mirror_count agent directories"
    else
      # ~/.claude/skills/ removed — clean stale symlinks from all agent dirs
      echo "🧹 No skills installed — cleaning stale symlinks from agent directories..."
      for profile in ${lib.concatStringsSep " " (map lib.escapeShellArg opencodeProfileNames)}; do
        rm -rf "$HOME/.config/$profile/skills" 2>/dev/null || true
        mkdir -p "$HOME/.config/$profile/skills"
      done
      rm -rf "$HOME/.codex/skills" "$HOME/.gemini/skills" "$HOME/.omp/agent/skills" 2>/dev/null || true
      echo "✓ Agent skill directories cleaned"
    fi
  ''
)
