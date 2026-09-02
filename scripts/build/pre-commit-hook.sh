#!/usr/bin/env bash
# pre-commit-hook.sh - Prevent committing broken NixOS config.
# Install: just install-hooks

set -euo pipefail

# Resolve symlinks: git runs this via .git/hooks/pre-commit -> ../../scripts/build/
SELF="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SELF")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"

DEADNIX_EXCLUDES=(
	./home-manager/modules/terminal/zellij/layouts.nix
)

print_info "Pre-commit: validating NixOS config..."

# Fast checks only — full build is too slow for a hook.
# Escalation: modules (fastest) → lint → format check → flake check.

print_info "Checking module imports..."
bash ./scripts/build/modules-check.sh

print_info "Linting..."
statix check --ignore '.git/**'
deadnix --fail --exclude "${DEADNIX_EXCLUDES[@]}" .

print_info "Checking formatting..."
# fd-based, not `nix fmt .`: nix fmt walks gitignored files too (e.g. the
# private inventory/permanent/servers.nix) and would fail the hook forever;
# fd honors .gitignore, matching `just format`.
fd -e nix -X nixfmt --strict --check 2>/dev/null || {
	print_error "Formatting check failed. Run 'just format' first."
	exit 1
}

print_info "Evaluating flake..."
nix flake check --no-build path:.

print_success "Pre-commit checks passed!"
