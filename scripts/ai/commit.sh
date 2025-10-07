#!/usr/bin/env bash
# commit.sh - Generate conventional commit messages using AI
# Usage: ./commit.sh (in any git repository with staged changes)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASK_SCRIPT="$SCRIPT_DIR/ask.sh"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Function to show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Generate conventional commit messages based on staged changes."
    echo "This script analyzes git staged changes and creates proper commit messages."
    echo ""
    echo "Examples:"
    echo "  $0              # Generate commit message for staged changes"
    echo "  $0 -d           # Use deep model for better analysis"
    echo ""
    echo "The script will:"
    echo "  1. Check for staged changes"
    echo "  2. Analyze the diff content"
    echo "  3. Generate conventional commit message"
    echo "  4. Copy to clipboard for easy use"
}

# Check if ask.sh exists
if [[ ! -f "$ASK_SCRIPT" ]]; then
    print_error "ask.sh not found at $ASK_SCRIPT"
    exit 1
fi

# Parse command line arguments
USE_DEEP_MODEL=false
if [[ $# -gt 0 ]]; then
    if [[ "$1" == "-d" || "$1" == "--deep" ]]; then
        USE_DEEP_MODEL=true
        shift
    fi

    if [[ $# -gt 0 ]] && ([[ "$1" == "-h" || "$1" == "--help" ]]); then
        show_usage
        exit 0
    fi
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    print_error "Not in a git repository"
    exit 1
fi

# Enhanced functions for better context
get_commit_context() {
    local num_commits=${1:-5}
    echo "Recent commit history (last $num_commits):"
    GIT_PAGER=cat git log --oneline -n "$num_commits" 2>/dev/null || echo "No previous commits"
}

get_branch_context() {
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    echo "Current branch: $current_branch"

    # Try to detect base branch
    if git remote get-url origin >/dev/null 2>&1; then
        local default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
        if [[ "$current_branch" != "$default_branch" ]]; then
            local ahead_count=$(git rev-list --count HEAD ^"origin/$default_branch" 2>/dev/null || echo "0")
            if [[ "$ahead_count" -gt 0 ]]; then
                echo "Commits ahead of $default_branch: $ahead_count"
            fi
        fi
    fi
}

analyze_changes() {
    echo "Change analysis:"

    # Categorize changes
    local new_files=$(GIT_PAGER=cat git diff --cached --name-status | grep '^A' | cut -f2- | tr '\n' ' ' || true)
    local modified_files=$(GIT_PAGER=cat git diff --cached --name-status | grep '^M' | cut -f2- | tr '\n' ' ' || true)
    local deleted_files=$(GIT_PAGER=cat git diff --cached --name-status | grep '^D' | cut -f2- | tr '\n' ' ' || true)

    [[ -n "$new_files" ]] && echo "New files: $new_files"
    [[ -n "$modified_files" ]] && echo "Modified files: $modified_files"
    [[ -n "$deleted_files" ]] && echo "Deleted files: $deleted_files"

    # Intelligent diff handling - use stat instead of full diff to avoid bat
    local diff_size=$(GIT_PAGER=cat git diff --cached | wc -l)
    if [[ "$diff_size" -gt 1000 ]]; then
        print_warning "Large diff detected ($diff_size lines). Using summarized analysis."
        GIT_PAGER=cat git diff --cached --stat=120,120
        echo ""
        echo "Key file changes:"
        GIT_PAGER=cat git diff --cached --numstat | head -15 | awk '{printf "  %s: +%s -%s lines\n", $3, $1, $2}'
    else
        # Use stat instead of full diff to avoid bat opening
        GIT_PAGER=cat git diff --cached --stat
    fi
}

# Check if there are staged changes
if ! git diff --cached --quiet; then
    print_info "Analyzing repository context and staged changes..."

    # Get comprehensive context
    echo ""
    get_branch_context
    echo ""
    get_commit_context
    echo ""
    analyze_changes

    # Enhanced system prompt with repository context awareness
    SYSTEM_PROMPT="You are an expert in Conventional Commits specification and repository analyst. Analyze the provided repository context, recent commit patterns, and current changes to generate exactly ONE proper conventional commit message.

CONTEXT ANALYSIS GUIDELINES:
- Consider recent commit history for consistency patterns
- Understand branch context (feature branch vs main branch)
- Analyze file types and categorize change impacts
- Choose scope based on main component affected
- Consider the change magnitude and user impact

CRITICAL: You must provide ONLY ONE commit message, not multiple options.

Rules:
1. Use format: <type>[optional scope]: <description>
2. Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, security, release, revert
3. Scope: reflect main component (auth, api, ui, config, scripts, ai, nixos, modules)
4. Description: short, imperative, user-facing impact focus
5. Maintain consistency with recent commit patterns
6. Use present tense, imperative mood ('add' not 'added')
7. Keep description under 50 characters when possible
8. For feature branches, use more descriptive scopes
9. For main branch, be more conservative with types

Change Type Guidelines:
- New functionality: feat[scope]: add feature description
- Bug fixes: fix[scope]: resolve issue description
- Documentation: docs[scope]: update documentation type
- Refactoring: refactor[scope]: improve code structure
- Configuration: chore[scope]: update configuration
- Performance: perf[scope]: optimize performance aspect
- Build/CI: ci[scope]: improve build/deployment process

Examples:
- feat(ai): add conventional commit message generator
- fix(nixos): resolve SOPS configuration issue
- docs(scripts): update AI assistant documentation
- refactor(modules): simplify configuration structure
- chore(config): update development environment settings

IMPORTANT: Generate exactly ONE commit message. Consider the repository context and recent patterns for consistency."

    # Get comprehensive repository analysis
    REPO_ANALYSIS=$(cat <<EOF
Repository Analysis:

$(get_branch_context)

$(get_commit_context 5)

$(analyze_changes)
EOF
)

    AI_PROMPT="Analyze this complete repository context and generate a conventional commit message:

$REPO_ANALYSIS

Based on the repository context, recent commit patterns, branch information, and current changes, provide an appropriate conventional commit message that maintains consistency with the project's commit history."

    # Call ask.sh to generate commit message, capturing only the final result
    if [[ "$USE_DEEP_MODEL" == "true" ]]; then
        COMMIT_MESSAGE=$("$ASK_SCRIPT" -s "$SYSTEM_PROMPT" -d "$AI_PROMPT" 2>/dev/null | tail -1)
    else
        COMMIT_MESSAGE=$("$ASK_SCRIPT" -s "$SYSTEM_PROMPT" "$AI_PROMPT" 2>/dev/null | tail -1)
    fi

    # Clean up the commit message (remove extra whitespace)
    COMMIT_MESSAGE=$(echo "$COMMIT_MESSAGE" | xargs)  # xargs trims whitespace

    # Copy to clipboard
    if command -v wl-copy >/dev/null 2>&1; then
        echo "$COMMIT_MESSAGE" | wl-copy
    fi

    echo ""
    # Display only the commit message
    echo "$COMMIT_MESSAGE"

else
    print_error "No staged changes found"
    print_info "Stage your changes first:"
    echo "  git add <files>    # Stage specific files"
    echo "  git add .          # Stage all changes"
    echo "  git diff --cached  # Preview staged changes"
    exit 1
fi
