#!/usr/bin/env bash
# Sync skills from GitHub repos to ~/.local/share/skills/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"

SKILLS_DIR="$HOME/.local/share/skills"
mkdir -p "$SKILLS_DIR"

# Format: "repo|skill-path|output-name"
SKILLS=(
	"vercel-labs/skills|find-skills|find-skills"
	"vercel-labs/agent-skills|react-best-practices|vercel-react-best-practices"
	"anthropics/skills|frontend-design|frontend-design"
	"remotion-dev/skills|remotion|remotion-best-practices"
	"vercel-labs/agent-browser|agent-browser|agent-browser"
	"inferen-sh/skills|tools/video/ai-video-generation|ai-video-generation"
	"nextlevelbuilder/ui-ux-pro-max-skill|.claude/skills/ui-ux-pro-max|ui-ux-pro-max"
	"obra/superpowers|brainstorming|brainstorming"
	"coreyhaines31/marketingskills|seo-audit|seo-audit"
	"vercel-labs/next-skills|next-best-practices|next-best-practices"
	"shadcn/ui|shadcn|shadcn"
	"obra/superpowers|systematic-debugging|systematic-debugging"
	"obra/superpowers|writing-plans|writing-plans"
	"squirrelscan/skills|audit-website|audit-website"
	"obra/superpowers|using-superpowers|using-superpowers"
	"anthropics/skills|skill-creator|skill-creator"
	"anthropics/skills|webapp-testing|webapp-testing"
	"obra/superpowers|test-driven-development|test-driven-development"
	"roin-orca/skills|simple|simple"
	"vercel-labs/agent-skills|web-design-guidelines|web-design-guidelines"
	"SimoneAvogadro/android-reverse-engineering-skill|plugins/android-reverse-engineering/skills/android-reverse-engineering|android-reverse-engineering"
	"Eyali1001/apkre|apk-audit|apk-audit"
	"narlyseorg/superhackers|security-assessment|security-assessment"
	"narlyseorg/superhackers|assessment-orchestrator|assessment-orchestrator"
	"o0o0o0admin/SKILLS-REPO_supercent-io-skills-template|.agent-skills/security-best-practices|security-best-practices"
	"o0o0o0admin/SKILLS-REPO_supercent-io-skills-template|.agent-skills/workflow-automation|workflow-automation"
	"microsoft/playwright-cli|playwright-cli|playwright-cli"
	"ChromeDevTools/chrome-devtools-mcp|skills/chrome-devtools-cli|chrome-devtools-cli"
	"callstackincubator/agent-device|agent-device|agent-device"
	"samber/cc-skills-golang|golang-benchmark|golang-benchmark"
	"samber/cc-skills-golang|golang-cli|golang-cli"
	"samber/cc-skills-golang|golang-code-style|golang-code-style"
	"samber/cc-skills-golang|golang-concurrency|golang-concurrency"
	"samber/cc-skills-golang|golang-context|golang-context"
	"samber/cc-skills-golang|golang-continuous-integration|golang-continuous-integration"
	"samber/cc-skills-golang|golang-data-structures|golang-data-structures"
	"samber/cc-skills-golang|golang-database|golang-database"
	"samber/cc-skills-golang|golang-dependency-injection|golang-dependency-injection"
	"samber/cc-skills-golang|golang-dependency-management|golang-dependency-management"
	"samber/cc-skills-golang|golang-design-patterns|golang-design-patterns"
	"samber/cc-skills-golang|golang-documentation|golang-documentation"
	"samber/cc-skills-golang|golang-error-handling|golang-error-handling"
	"samber/cc-skills-golang|golang-lint|golang-lint"
	"samber/cc-skills-golang|golang-modernize|golang-modernize"
	"samber/cc-skills-golang|golang-naming|golang-naming"
	"samber/cc-skills-golang|golang-observability|golang-observability"
	"samber/cc-skills-golang|golang-performance|golang-performance"
	"samber/cc-skills-golang|golang-popular-libraries|golang-popular-libraries"
	"samber/cc-skills-golang|golang-project-layout|golang-project-layout"
	"samber/cc-skills-golang|golang-safety|golang-safety"
	"samber/cc-skills-golang|golang-security|golang-security"
	"samber/cc-skills-golang|golang-structs-interfaces|golang-structs-interfaces"
	"samber/cc-skills-golang|golang-testing|golang-testing"
	"samber/cc-skills-golang|golang-troubleshooting|golang-troubleshooting"
)

# Ensure SKILL.md has required frontmatter fields (name, description).
# Pi and other agents require both; some upstream skills omit them.
normalize_skill_frontmatter() {
	local skill_md="$1"
	local fallback_name="$2"
	[[ -f "$skill_md" ]] || return 0

	# Check if file has YAML frontmatter (starts with ---)
	local first_line
	first_line=$(head -1 "$skill_md")
	[[ "$first_line" == "---" ]] || return 0

	local has_name=0 has_desc=0
	grep -q '^name:' "$skill_md" && has_name=1
	grep -q '^description:' "$skill_md" && has_desc=1

	# If both present, ensure name is in frontmatter (first --- block)
	if [[ "$has_name" -eq 1 ]] && [[ "$has_desc" -eq 1 ]]; then
		# Deduplicate: if name appears outside frontmatter, remove it
		local end_fm
		end_fm=$(grep -n '^---' "$skill_md" | sed -n '2p' | cut -d: -f1)
		if [[ -n "$end_fm" ]]; then
			# Count name: lines; if more than 1, remove extras after frontmatter
			local name_count
			name_count=$(grep -c '^name:' "$skill_md") || true
			if [[ "$name_count" -gt 1 ]]; then
				# Remove name: lines outside frontmatter
				sed -i "${end_fm},\$s/^name:.*//" "$skill_md"
			fi
		fi
		return 0
	fi

	# Missing fields — patch them in
	local needs_patch=0
	local patch_name="" patch_desc=""

	if [[ "$has_name" -eq 0 ]]; then
		patch_name="name: $fallback_name"
		needs_patch=1
	fi
	if [[ "$has_desc" -eq 0 ]]; then
		# Derive description from the first H1 heading after frontmatter
		local h1
		h1=$(grep -m1 '^# ' "$skill_md" | sed 's/^# //' | head -c 120) || true
		if [[ -n "$h1" ]]; then
			patch_desc="description: $h1"
		else
			patch_desc="description: $fallback_name"
		fi
		needs_patch=1
	fi

	if [[ "$needs_patch" -eq 1 ]]; then
		# Insert after the first --- line
		local insert_line=""
		[[ -n "$patch_name" ]] && insert_line="${insert_line}${patch_name}\n"
		[[ -n "$patch_desc" ]] && insert_line="${insert_line}${patch_desc}\n"
		sed -i "1a\\${insert_line}" "$skill_md"
	fi
}

echo "Syncing ${#SKILLS[@]} skills to $SKILLS_DIR..."

success=0
failed=0
current_tmpdir=""

cleanup_tmpdir() {
	[[ -n "${current_tmpdir:-}" ]] && rm -rf "$current_tmpdir"
}
trap cleanup_tmpdir EXIT

for entry in "${SKILLS[@]}"; do
	IFS='|' read -r repo skill_path skill_name <<<"$entry"
	target="$SKILLS_DIR/$skill_name"

	echo -n "  → $skill_name: "

	tmpdir=$(mktemp -d)
	current_tmpdir="$tmpdir"

	# Clone the repo
	if ! git clone --quiet --depth 1 --filter=blob:none --sparse "https://github.com/$repo.git" "$tmpdir/repo" 2>/dev/null; then
		print_error "clone failed for ${skill_name}"
		failed=$((failed + 1))
		rm -rf "$tmpdir"
		continue
	fi

	# Try to find the skill directory
	skill_dir=""

	# 1. Try exact skill_path with skills/ prefix
	git -C "$tmpdir/repo" sparse-checkout set "skills/$skill_path" 2>/dev/null || true
	[[ -f "$tmpdir/repo/skills/$skill_path/SKILL.md" ]] && skill_dir="$tmpdir/repo/skills/$skill_path"

	# 2. Try skills/skill_path directly
	if [[ -z "$skill_dir" ]]; then
		git -C "$tmpdir/repo" sparse-checkout set "skills" 2>/dev/null || true
		[[ -f "$tmpdir/repo/skills/$skill_path/SKILL.md" ]] && skill_dir="$tmpdir/repo/skills/$skill_path"
	fi

	# 3. Try skill_path at root
	if [[ -z "$skill_dir" ]]; then
		git -C "$tmpdir/repo" sparse-checkout set "$skill_path" 2>/dev/null || true
		[[ -f "$tmpdir/repo/$skill_path/SKILL.md" ]] && skill_dir="$tmpdir/repo/$skill_path"
	fi

	# 4. Try plugins pattern
	if [[ -z "$skill_dir" ]]; then
		git -C "$tmpdir/repo" sparse-checkout set "plugins" 2>/dev/null || true
		found=$(find "$tmpdir/repo/plugins" -maxdepth 5 -name "SKILL.md" 2>/dev/null | head -1)
		[[ -n "$found" ]] && skill_dir=$(dirname "$found")
	fi

	if [[ -n "$skill_dir" && -f "$skill_dir/SKILL.md" ]]; then
		rm -rf "$target"
		cp -r "$skill_dir" "$target"
		normalize_skill_frontmatter "$target/SKILL.md" "$skill_name"
		print_success "${skill_name}"
		success=$((success + 1))
	else
		print_warning "SKILL.md not found for ${skill_name}"
		failed=$((failed + 1))
	fi

	rm -rf "$tmpdir"
	current_tmpdir=""
done

echo ""
print_success "Synced $success skills ($failed failed) to $SKILLS_DIR"

# --- Mirror to agent skill directories ---
# The skills CLI creates symlinks in ~/.claude/skills/ pointing to ~/.agents/skills/,
# but home-manager activation moves ~/.agents/skills/ away (for OpenCode dedup),
# breaking all those symlinks.  Instead, we copy real directories so every agent
# that reads ~/.claude/skills/ always sees valid skill trees.
mirror_count=0
for agent_dir in "$HOME/.claude/skills" "$HOME/.codex/skills"; do
	[[ -d "$agent_dir" ]] || continue
	for skill_dir in "$SKILLS_DIR"/*; do
		[[ -d "$skill_dir" ]] || continue
		name=$(basename "$skill_dir")
		target="$agent_dir/$name"
		# Replace broken symlinks and missing dirs; leave existing real dirs alone
		needs_update=0
		if [[ -L "$target" ]] && [[ ! -d "$target" ]]; then needs_update=1; fi
		if [[ ! -e "$target" ]]; then needs_update=1; fi
		if [[ "$needs_update" -eq 1 ]]; then
			rm -rf "$target" 2>/dev/null || true
			cp -r "$skill_dir" "$target"
			mirror_count=$((mirror_count + 1))
		fi
	done
done
if [[ $mirror_count -gt 0 ]]; then
	print_success "Mirrored $mirror_count skills to ~/.claude/skills and ~/.codex/skills"
fi

# Mirror to pi agent directory with name-field matching (pi requires
# symlink dir name to match the "name" field in SKILL.md frontmatter).
if [[ -d "$HOME/.omp/agent/skills" ]]; then
	pi_count=0
	for skill_dir in "$SKILLS_DIR"/*; do
		[[ -d "$skill_dir" ]] || continue
		name=$(basename "$skill_dir")
		# Read omp's expected name from SKILL.md frontmatter
		if [[ -f "$skill_dir/SKILL.md" ]]; then
			fm_name=$(grep '^name:' "$skill_dir/SKILL.md" | head -1 | sed 's/^name:[[:space:]]*//' | tr -d '"' | xargs 2>/dev/null)
			[[ -n "$fm_name" ]] && name="$fm_name"
		fi
		target="$HOME/.omp/agent/skills/$name"
		needs_update=0
		if [[ -L "$target" ]] && [[ ! -d "$target" ]]; then needs_update=1; fi
		if [[ ! -e "$target" ]]; then needs_update=1; fi
		if [[ "$needs_update" -eq 1 ]]; then
			rm -rf "$target" 2>/dev/null || true
			ln -sfn "$skill_dir" "$target"
			pi_count=$((pi_count + 1))
		fi
	done
	if [[ $pi_count -gt 0 ]]; then
		print_success "Mirrored $pi_count skills to ~/.omp/agent/skills"
	fi
fi

echo ""
echo "Run 'just home' to symlink to opencode profiles."

exit $failed
