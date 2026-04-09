set shell := ["/usr/bin/env", "bash", "-c"]
set quiet

JUST := "just -u -f " + justfile()
header := "Available tasks:\n"
host := `hostname`

_default:
    @{{JUST}} --list-heading "{{header}}" --list

# Format all .nix files
format:
    @echo -e "\n➤ Formatting Nix files"
    @nix run nixpkgs#time -- -f "⏱ Completed in %E" fd -e nix -X nixfmt --strict
    @echo "✔ Formatting passed!"

# Lint all .nix files and bash scripts
lint:
    @echo -e "\n➤ Linting Nix files…"
    @nix run nixpkgs#time -- -f "⏱ Completed in %E" nix run nixpkgs#statix -- check --ignore '.git/**'
    @echo "✔ Nix linting passed!"
    @echo -e "\n➤ Checking Bash scripts…"
    @nix run nixpkgs#time -- -f "⏱ Completed in %E" find . -name "*.sh" -not -path "./.git/*" -exec nix run nixpkgs#shellcheck -- {} +
    @echo "✔ ShellCheck passed!"

# Check all missing imports
modules:
    @echo -e "\n➤ Checking modules"
    @nix run nixpkgs#time -- -f "⏱ Completed in %E" ./scripts/build/modules-check.sh

# Security-focused repository checks
security:
    @echo -e "\n➤ Running security audit"
    @nix run nixpkgs#time -- -f "⏱ Completed in %E" ./scripts/build/security-audit.sh

# Performance diagnostics (boot/session/report)
perf top="15":
    @echo -e "\n➤ Running performance audit"
    @nix run nixpkgs#time -- -f "⏱ Completed in %E" ./scripts/build/performance-audit.sh {{top}}

# Systemd service hardening exposure report
hardening:
    @echo -e "\n➤ Running systemd hardening audit"
    @nix run nixpkgs#time -- -f "⏱ Completed in %E" ./scripts/build/systemd-hardening-audit.sh

# Evaluate flake outputs without switching
check:
    @echo -e "\n➤ Evaluating flake"
    @nix run nixpkgs#time -- -f "⏱ Completed in %E" nix flake check "path:$PWD"

# Measure evaluation time for core flake outputs
eval-audit target="all":
    @echo -e "\n➤ Running evaluation audit"
    @nix run nixpkgs#time -- -f "⏱ Completed in %E" ./scripts/build/eval-audit.sh {{target}}

# Fast eval timing for the current host only
eval-current:
    @echo -e "\n➤ Running current-host evaluation audit"
    @nix run nixpkgs#time -- -f "⏱ Completed in %E" ./scripts/build/eval-audit.sh {{host}}

# Switch Home-Manager generation
home:
    @echo -e "\n➤ Switching Home-Manager…"
    nh home switch '.?submodules=1' --diff never --no-update-lock-file --no-write-lock-file

# Switch NixOS generation
nixos target=host:
    @echo -e "\n➤ Rebuilding NixOS…"
    nh os switch . --hostname {{target}} --diff never --no-update-lock-file --no-write-lock-file

# Fast path: skip pre-activation validation checks
nixos-fast target=host:
    @echo -e "\n➤ Rebuilding NixOS (fast mode)…"
    NH_NO_VALIDATE=1 nh os switch . --hostname {{target}} --diff never --no-update-lock-file --no-write-lock-file --no-nom

# Fast local quality gate (no switch)
qa:
    @echo -e "\n➤ Running local QA (no switch)…"
    {{JUST}} modules
    {{JUST}} security
    {{JUST}} check
    {{JUST}} eval-audit

# Fast local QA for iterative work (current host only)
qa-fast:
    @echo -e "\n➤ Running fast local QA (current host, no switch)…"
    {{JUST}} modules
    {{JUST}} security
    {{JUST}} eval-current

# All of the above, in order
all:
    @echo -e "\n➤ Running full pipeline…"
    {{JUST}} modules
    {{JUST}} lint
    {{JUST}} format
    {{JUST}} security
    {{JUST}} check
    {{JUST}} nixos
    {{JUST}} home
    @echo -e "✔ All done!"

# Update all flake inputs
update:
	nix flake update

# Update Nixpkgs
update-pkgs:
    @echo -e "\n➤ Updating Nixpkgs…"
    nix flake update nixpkgs
# Update Nixpkgs-stable
update-pkgs-stable:
    @echo -e "\n➤ Updating Nixpkgs-stable…"
    nix flake update nixpkgs-stable

# Clean up build artifacts and caches
clean:
	@echo -e "\n➤ Cleaning up build artifacts and caches…"
	@echo "[DEL] Cleaning Nix store (1 day older)..."
	nh clean all --keep 1
	@echo "[HM] Cleaning Home Manager generations..."
	home-manager expire-generations "-1 days"
	@echo "[OPT] Optimizing Nix store..."
	nix store optimise
	@echo -e "✔ Cleanup completed!"

# Edit secrets with SOPS
sops-edit:
    @echo -e "\n➤ Editing secrets with SOPS…"
    @echo "Decrypting secrets..."
    @sops --decrypt secrets/secrets.yaml > secrets/secrets-decrypted.yaml
    @echo "Opening VS Code (close the tab/window when done editing)..."
    @code --wait secrets/secrets-decrypted.yaml
    @echo "Encrypting secrets back..."
    @sops --encrypt secrets/secrets-decrypted.yaml > secrets/secrets.yaml
    @rm secrets/secrets-decrypted.yaml
    @echo "✔ Encrypted and cleaned up!"

# View decrypted secrets (read-only)
sops-view:
	@echo -e "\n➤ Viewing decrypted secrets…"
	sops --decrypt secrets/secrets.yaml

# Decrypt secrets to file for manual editing
sops-decrypt:
	@echo -e "\n➤ Decrypting secrets to secrets/secrets-decrypted.yaml…"
	sops --decrypt secrets/secrets.yaml > secrets/secrets-decrypted.yaml
	@echo "Edit secrets/secrets-decrypted.yaml then run: just sops-encrypt"

# Encrypt file back to secrets
sops-encrypt:
	@echo -e "\n➤ Encrypting secrets/secrets-decrypted.yaml to secrets/secrets.yaml…"
	sops --encrypt secrets/secrets-decrypted.yaml > secrets/secrets.yaml
	@rm secrets/secrets-decrypted.yaml
	@echo "✔ Encrypted and cleaned up!"

# Add a single secret
secrets-add key value:
	@echo -e "\n➤ Adding secret: {{key}} = {{value}}"
	sops --set '["{{key}}"] "{{value}}"' secrets/secrets.yaml
	@echo "✔ Secret added!"

# Setup SOPS age key
sops-setup:
	@echo -e "\n➤ Setting up SOPS age key…"
	./scripts/sops/sops-setup.sh

# Setup SSH and GPG keys from SOPS
setup-keys:
	@echo -e "\n➤ Setting up SSH and GPG keys from SOPS…"
	./scripts/sops/setup-keys.sh

# Show SOPS public key
sops-key:
	@echo -e "\n➤ SOPS public key:"
	@sops --version && echo ""
	@if [ -f ~/.config/sops/age/keys.txt ]; then \
		echo "Public key:"; \
		nix shell nixpkgs#age -c age-keygen -y ~/.config/sops/age/keys.txt; \
	else \
		echo "No age key found. Run 'just sops-setup' to create one."; \
	fi

# Sync skills from GitHub to ~/.local/share/skills/
skills-sync:
    @echo -e "\n➤ Syncing skills from GitHub…"
    @./scripts/ai/skills-sync.sh
