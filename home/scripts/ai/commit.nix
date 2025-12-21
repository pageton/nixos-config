{pkgs, ...}:
pkgs.writeShellScriptBin "ai-commit" ''
    # commit.sh - Generate conventional commit messages using AI
    # Usage: ai-commit (in any git repository with staged changes)

    set -euo pipefail

    # Colors for output
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    NC='\033[0m' # No Color

    # Function to print colored output
    print_info() { echo -e "''${BLUE}ℹ''${NC} $1"; }
    print_success() { echo -e "''${GREEN}✓''${NC} $1"; }
    print_error() { echo -e "''${RED}✗''${NC} $1"; }

    # Function to show usage
    show_usage() {
        echo "Usage: ai-commit [options]"
        echo ""
        echo "Generate conventional commit messages based on staged changes using AI."
        echo "This script analyzes git staged changes and creates proper commit messages."
        echo ""
        echo "Examples:"
        echo "  ai-commit              # Generate commit messages for staged changes"
        echo "  ai-commit -h           # Show this help message"
        echo ""
        echo "The script will:"
        echo "  1. Check for staged changes"
        echo "  2. Analyze the diff content and repository context"
        echo "  3. Generate 3 conventional commit message options"
        echo "  4. Copy first option to clipboard for easy use"
    }

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Check if we're in a git repository
    if ! ${pkgs.git}/bin/git rev-parse --git-dir >/dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi

    # Enhanced functions for better context
    get_commit_context() {
        local num_commits=''${1:-5}
        echo "Recent commit history (last $num_commits):"
        local git_output
        git_output="$(GIT_PAGER=cat ${pkgs.git}/bin/git log --oneline -n "$num_commits" 2>/dev/null || echo "No previous commits")"
        echo "$git_output"
    }

    get_branch_context() {
        local current_branch
        current_branch=$(${pkgs.git}/bin/git branch --show-current 2>/dev/null || echo "unknown")
        echo "Current branch: $current_branch"

        # Try to detect base branch
        if ${pkgs.git}/bin/git remote get-url origin >/dev/null 2>&1; then
            local default_branch
            default_branch=$(${pkgs.git}/bin/git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
            if [[ "$current_branch" != "$default_branch" ]]; then
                local ahead_count
                ahead_count=$(${pkgs.git}/bin/git rev-list --count HEAD ^"origin/$default_branch" 2>/dev/null || echo "0")
                if [[ "$ahead_count" -gt 0 ]]; then
                    echo "Commits ahead of $default_branch: $ahead_count"
                fi
            fi
        fi
    }

    analyze_project_type() {
        echo "Project Type Analysis:"

        # Detect project type from files and structure
        local project_type="Unknown"
        local languages=()
        local frameworks=()
        local build_systems=()

        # Analyze file extensions and patterns
        local files
        files="$(${pkgs.git}/bin/git ls-files 2>/dev/null | head -50 || echo "")"

        # Detect languages
        if echo "$files" | grep -E '\.(js|jsx|ts|tsx|json)$' >/dev/null; then
            languages+=("JavaScript/TypeScript")
            if echo "$files" | grep -E 'package\.json$' >/dev/null; then
                build_systems+=("npm/yarn")
            fi
            if echo "$files" | grep -E 'react|jsx|tsx' >/dev/null; then
                frameworks+=("React")
            fi
            if echo "$files" | grep -E 'vue|svelte|angular' >/dev/null; then
                frameworks+=("Frontend Framework")
            fi
        fi

        if echo "$files" | grep -E '\.(py)$' >/dev/null; then
            languages+=("Python")
            if echo "$files" | grep -E 'requirements\.txt|setup\.py|pyproject\.toml$' >/dev/null; then
                build_systems+=("pip/poetry")
            fi
            if echo "$files" | grep -E 'django|flask|fastapi' >/dev/null; then
                frameworks+=("Web Framework")
            fi
        fi

        if echo "$files" | grep -E '\.(rs)$' >/dev/null; then
            languages+=("Rust")
            if echo "$files" | grep -E 'Cargo\.toml$' >/dev/null; then
                build_systems+=("Cargo")
            fi
        fi

        if echo "$files" | grep -E '\.(go)$' >/dev/null; then
            languages+=("Go")
            if echo "$files" | grep -E 'go\.mod$' >/dev/null; then
                build_systems+=("Go modules")
            fi
        fi

        if echo "$files" | grep -E '\.(java|kt)$' >/dev/null; then
            languages+=("Java/Kotlin")
            if echo "$files" | grep -E 'pom\.xml|build\.gradle$' >/dev/null; then
                build_systems+=("Maven/Gradle")
            fi
        fi

        if echo "$files" | grep -E '\.(c|cpp|h|hpp)$' >/dev/null; then
            languages+=("C/C++")
            if echo "$files" | grep -E 'Makefile|CMakeLists\.txt$' >/dev/null; then
                build_systems+=("Make/CMake")
            fi
        fi

        if echo "$files" | grep -E '\.(nix|flake)$' >/dev/null; then
            languages+=("Nix/NixOS")
            build_systems+=("Nix Flakes")
        fi

        if echo "$files" | grep -E '\.dockerfile$|docker-compose\.yml$' >/dev/null; then
            frameworks+=("Docker")
        fi

        # Detect CI/CD
        if echo "$files" | grep -E '\.(yml|yaml)$' | grep -E 'github|gitlab|ci|cd' >/dev/null; then
            frameworks+=("CI/CD")
        fi

        # Detect project type
        if echo "$files" | grep -E 'README|CHANGELOG|LICENSE' >/dev/null; then
            project_type="Library/Package"
        elif echo "$files" | grep -E 'src|app|index\.' >/dev/null; then
            project_type="Application"
        elif echo "$files" | grep -E '\.(nix|yaml|toml)$' >/dev/null; then
            project_type="Configuration"
        elif echo "$files" | grep -E '\.(md|txt|rst)$' >/dev/null; then
            project_type="Documentation"
        fi

        echo "  Type: $project_type"
        [[ ''${#languages[@]} -gt 0 ]] && echo "  Languages: ''${languages[*]}"
        [[ ''${#frameworks[@]} -gt 0 ]] && echo "  Frameworks: ''${frameworks[*]}"
        [[ ''${#build_systems[@]} -gt 0 ]] && echo "  Build Systems: ''${build_systems[*]}"

        # File structure insights
        local total_files
        total_files="$(echo "$files" | wc -l | tr -d ' ')"
        echo "  Total files in repo: $total_files"

        # Directory structure
        local dirs
        dirs="$(echo "$files" | xargs dirname | sort -u | head -10 | tr '\n' ' ')"
        [[ -n "$dirs" ]] && echo "  Main directories: $dirs"
    }

    analyze_changes() {
        echo "Change analysis:"

        # Categorize changes
        local new_files
        new_files="$(GIT_PAGER=cat ${pkgs.git}/bin/git diff --cached --name-status | grep '^A' | cut -f2- | tr '\n' ' ' || true)"
        local modified_files
        modified_files="$(GIT_PAGER=cat ${pkgs.git}/bin/git diff --cached --name-status | grep '^M' | cut -f2- | tr '\n' ' ' || true)"
        local deleted_files
        deleted_files="$(GIT_PAGER=cat ${pkgs.git}/bin/git diff --cached --name-status | grep '^D' | cut -f2- | tr '\n' ' ' || true)"

        [[ -n "$new_files" ]] && echo "New files: $new_files"
        [[ -n "$modified_files" ]] && echo "Modified files: $modified_files"
        [[ -n "$deleted_files" ]] && echo "Deleted files: $deleted_files"

        # Enhanced diff analysis with actual code changes
        local diff_size
        diff_size="$(GIT_PAGER=cat ${pkgs.git}/bin/git diff --cached | wc -l)"

        echo ""
        echo "Diff Statistics:"
        local diff_stat
        diff_stat="$(GIT_PAGER=cat ${pkgs.git}/bin/git diff --cached --stat=120,120)"
        echo "$diff_stat"

        echo ""
        echo "Detailed Changes (first 2000 lines):"
        local full_diff
        full_diff="$(GIT_PAGER=cat ${pkgs.git}/bin/git diff --cached | head -2000)"
        echo "$full_diff"
    }

    # Loading animation
    show_loading() {
        local pid=$1
        local delay=0.1
        local spinstr='|/\-'
        while ps -p "$pid" >/dev/null 2>&1; do
            local temp=''${spinstr#?}
            printf "\r Generating commits... %c" "$spinstr"
            local spinstr=$temp''${spinstr%"$temp"}
            sleep $delay
        done
        # Clear the entire line properly
        printf "\r\033[K"
    }

    # Check if there are staged changes
    if ! ${pkgs.git}/bin/git diff --cached --quiet; then
        # Get comprehensive context silently (except for analyze_changes which includes diff)
        get_branch_context >/dev/null
        get_commit_context >/dev/null

        # Enhanced system prompt based on latest best practices
        SYSTEM_PROMPT="You are an expert software engineer specializing in writing exceptional git commit messages following the Conventional Commits 1.0.0 specification.

  ## CORE PRINCIPLES

  Your sole responsibility is to analyze git diff output and generate commit messages that:
  - Follow Conventional Commits specification precisely
  - Use imperative mood (\"add\" not \"added\", \"fix\" not \"fixed\")
  - Are concise yet descriptive (max 72 characters for subject)
  - Focus on WHAT changed and WHY, not HOW
  - Provide meaningful context for future code reviewers

  ## CONVENTIONAL COMMIT FORMAT

  \`\`\`
  <type>(<scope>): <subject>

  [optional body]

  [optional footer]
  \`\`\`

  **Subject Line Rules:**
  - Maximum 72 characters (including type and scope)
  - Use imperative present tense
  - No period at the end
  - Lowercase after colon

  ## COMMIT TYPES (in priority order)

  **feat**: New feature or functionality for end users
    - Adding new capabilities, features, or user-facing functionality
    - Example: \`feat(auth): add OAuth2 login support\`

  **fix**: Bug fix or error correction
    - Resolving defects, errors, or broken functionality
    - Example: \`fix(api): resolve null pointer in user endpoint\`

  **perf**: Performance improvements
    - Optimizations that improve speed, memory, or efficiency
    - Example: \`perf(db): optimize user query with indexing\`

  **refactor**: Code restructuring without functional changes
    - Internal code improvements, reorganization, or cleanup
    - Example: \`refactor(utils): extract validation to separate module\`

  **docs**: Documentation only changes
    - README, comments, API docs, guides
    - Example: \`docs(readme): update installation instructions\`

  **style**: Code style and formatting
    - Whitespace, formatting, linting, semicolons (no code logic change)
    - Example: \`style(components): apply prettier formatting\`

  **test**: Test additions or modifications
    - Adding missing tests, correcting existing tests
    - Example: \`test(auth): add unit tests for login flow\`

  **build**: Build system and dependencies
    - Changes to build process, dependencies, package configurations
    - Example: \`build(deps): upgrade react to v18.3.0\`

  **ci**: CI/CD pipeline changes
    - GitHub Actions, GitLab CI, Jenkins, deployment configs
    - Example: \`ci(actions): add automated testing workflow\`

  **chore**: Maintenance tasks and housekeeping
    - Routine tasks, configuration updates, non-production code
    - Example: \`chore(config): update editor settings\`

  **revert**: Reverting previous commits
    - Undoing previous changes
    - Example: \`revert(api): revert \"add rate limiting\"\`

  **security**: Security improvements and fixes
    - Vulnerability patches, security hardening
    - Example: \`security(auth): prevent session hijacking\`

  ## SCOPE GUIDELINES

  The scope should be:
  - Brief (2-15 characters)
  - Represent the affected component/module
  - Use natural boundaries (api, ui, db, auth, utils, config)
  - Match project structure when possible
  - Omit if change is global or unclear

  Examples:
  - \`feat(api): add user registration endpoint\`
  - \`fix(components): resolve button click handler\`
  - \`refactor(database): simplify query builder\`
  - \`docs: update contributing guidelines\` (no scope - global documentation)

  ## ANALYSIS STRATEGY

  When analyzing diff output:

  1. **Identify Primary Intent**: What is the main purpose?
     - Is it adding functionality? → feat
     - Fixing a bug? → fix
     - Improving performance? → perf
     - Restructuring code? → refactor

  2. **Assess Scope of Changes**:
     - Single component/module → use specific scope
     - Multiple components → use broader scope or omit
     - Configuration/tooling → use appropriate scope

  3. **Determine Impact Level**:
     - User-facing changes → prioritize feat/fix
     - Internal improvements → refactor/perf
     - Infrastructure → build/ci/chore

  4. **Focus on Intent, Not Implementation**:
     - BAD: \`refactor(auth): change variable names\`
     - GOOD: \`refactor(auth): improve code readability\`

  5. **Ignore Noise**:
     - Skip test file changes unless they're primary
     - Ignore whitespace-only changes unless explicitly about formatting
     - Don't mention every file touched

  ## BREAKING CHANGES

  For breaking changes, use \`!\` after type/scope:
  - \`feat(api)!: change user endpoint response format\`
  - \`refactor!: remove deprecated authentication methods\`

  ## EXAMPLES BY PROJECT TYPE

  **Web Application:**
  \`\`\`
  feat(auth): implement password reset flow
  fix(cart): resolve checkout button disable state
  perf(images): lazy load product thumbnails
  refactor(components): extract reusable card component
  \`\`\`

  **CLI Tool:**
  \`\`\`
  feat(cli): add batch processing mode
  fix(parser): handle malformed input gracefully
  refactor(commands): simplify command structure
  docs(usage): add examples for common workflows
  \`\`\`

  **Library/Package:**
  \`\`\`
  feat(api): add async streaming support
  fix(types): resolve TypeScript generic constraints
  perf(core): optimize tree traversal algorithm
  docs(api): document public methods with examples
  \`\`\`

  **Infrastructure/Configuration:**
  \`\`\`
  fix(docker): resolve networking issue in compose
  ci(github): add automated security scanning
  chore(k8s): update deployment resource limits
  build(deps): bump dependencies to latest versions
  \`\`\`

  ## OUTPUT FORMAT

  Generate exactly 3 commit message options, each exploring a different perspective:

  1. **Primary perspective** - The most obvious/important change
  2. **Alternative perspective** - A different valid interpretation
  3. **Detailed perspective** - More specific or nuanced view

  Each message MUST:
  - Be on its own line
  - Start with the number and period (\"1. \", \"2. \", \"3. \")
  - Follow conventional commit format exactly
  - Be concise and actionable
  - Focus on actual code changes from the diff

  Example output format:
  \`\`\`
  1. feat(auth): add OAuth2 authentication flow
  2. feat(security): implement third-party login providers
  3. feat(user): enable social authentication options
  \`\`\`

  ## CRITICAL RULES

  - **ALWAYS analyze the actual diff content** - the code changes are your source of truth
  - **NEVER make assumptions** beyond what the diff shows
  - **FOCUS on user impact** when applicable, technical details otherwise
  - **BE SPECIFIC** - avoid vague terms like \"update\", \"improve\", \"modify\"
  - **STAY CONCISE** - respect the 72 character limit
  - **USE IMPERATIVE MOOD** - \"add\" not \"adds\" or \"added\"
  - **IGNORE test files** unless they constitute the majority of changes
  - **EMPHASIZE breaking changes** that affect external interfaces or data models"

        # Get comprehensive repository analysis with actual diff content
        PROJECT_INSIGHTS=$(analyze_project_type)

        # Get complete context including diff
        REPO_ANALYSIS=$(cat <<EOF
  Repository Analysis:

  === PROJECT TYPE & STRUCTURE ===
  $PROJECT_INSIGHTS

  === GIT CONTEXT ===
  $(get_branch_context)

  $(get_commit_context 5)

  === STAGED CHANGES (COMPLETE DIFF) ===
  $(analyze_changes)
  EOF
  )

        AI_PROMPT="Analyze the git diff output below and generate 3 distinct conventional commit message options.

  $REPO_ANALYSIS

  INSTRUCTIONS:
  1. Focus primarily on the ACTUAL CODE CHANGES shown in the diff
  2. Identify the primary type (feat, fix, refactor, etc.) based on what the code does
  3. Determine appropriate scope from affected files/modules
  4. Write concise, imperative subject lines (max 72 chars)
  5. Generate 3 different valid perspectives on these changes
  6. Each option should be a complete, standalone commit message

  Provide exactly 3 numbered options following conventional commit format:"

        # Call ai-ask to generate commit message options
        OUTPUT_FILE=$(mktemp)
        ai-ask -s "$SYSTEM_PROMPT" "$AI_PROMPT" 2>/dev/null > "$OUTPUT_FILE" &
        bg_pid=$!
        show_loading $bg_pid
        wait $bg_pid
        COMMIT_OPTIONS=$(tr -d '\0' < "$OUTPUT_FILE")
        rm -f "$OUTPUT_FILE"

        # Extract numbered options from the AI response
        option1=$(echo "$COMMIT_OPTIONS" | grep -E '^1\.' | sed 's/^1\. *//' | head -1)
        option2=$(echo "$COMMIT_OPTIONS" | grep -E '^2\.' | sed 's/^2\. *//' | head -1)
        option3=$(echo "$COMMIT_OPTIONS" | grep -E '^3\.' | sed 's/^3\. *//' | head -1)

        # If no numbered options found, try to extract any commit messages
        if [[ -z "$option1" ]]; then
            all_commits=$(echo "$COMMIT_OPTIONS" | grep -E '^(feat|fix|refactor|docs|style|test|chore|perf|ci|build|security|revert)' | head -3)

            IFS=$'\n' read -r option1 option2 option3 <<< "$all_commits"
        fi

        # Display the 3 options
        echo ""
        print_info "Suggested commit messages:"
        echo ""

        if [[ -n "$option1" ]]; then
            echo "1. $option1"
        fi

        if [[ -n "$option2" ]]; then
            echo "2. $option2"
        fi

        if [[ -n "$option3" ]]; then
            echo "3. $option3"
        fi

        # Copy first option to clipboard for convenience
        if [[ -n "$option1" ]] && command -v wl-copy >/dev/null 2>&1; then
            echo "$option1" | wl-copy
            echo ""
            print_success "First option copied to clipboard!"
        fi

    else
        print_error "No staged changes found"
        print_info "Stage your changes first:"
        echo "  git add <files>    # Stage specific files"
        echo "  git add .          # Stage all changes"
        echo "  git diff --cached  # Preview staged changes"
        exit 1
    fi
''

