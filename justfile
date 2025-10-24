set shell := ["/usr/bin/env", "bash", "-c"]
set quiet

JUST := "just -u -f " + justfile()
header := "Available tasks:\n"

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
    @nix run nixpkgs#time -- -f "⏱ Completed in %E" bash ./scripts/build/modules-check.sh

# Switch Home-Manager generation
home:
    @echo -e "\n➤ Switching Home-Manager…"
    nh home switch '.?submodules=1'

# Switch NixOS generation
nixos:
    @echo -e "\n➤ Rebuilding NixOS…"
    nh os switch .

# All of the above, in order
all:
    @echo -e "\n➤ Running full pipeline…"
    {{JUST}} modules
    {{JUST}} lint
    {{JUST}} format
    {{JUST}} nixos
    {{JUST}} home
    @echo -e "✔ All done!"

# Update all flake inputs
update:
	nix flake update

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
