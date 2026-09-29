set shell := ["/usr/bin/env", "bash", "-c"]
set quiet

JUST := "just -u -f " + justfile()
header := "Available tasks:\n"
host := `hostname`

_default:
    @{{JUST}} --list-heading "{{header}}" --list

# Format Nix and shell files
format:
    @echo -e "\n➤ Formatting Nix files"
    @nix run nixpkgs#time -- -f "⏱ Completed in %E" fd -e nix -X nixfmt --strict
    @echo "➤ Formatting shell scripts"
    @files=$(git ls-files --cached --others --exclude-standard -- '*.sh'); \
      if [ -n "$files" ]; then nix run nixpkgs#shfmt -- -ci -i 2 -w $files; fi
    @echo "✔ Formatting passed!"

# Lint Nix and shell files
lint:
    @echo -e "\n➤ Linting Nix files…"
    @nix run nixpkgs#time -- -f "⏱ Completed in %E" nix run nixpkgs#statix -- check --ignore '.git/**'
    @echo "➤ Linting shell scripts…"
    @files=$(git ls-files --cached --others --exclude-standard -- '*.sh'); \
      if [ -n "$files" ]; then nix run nixpkgs#shellcheck -- -x $files && \
        nix run nixpkgs#shfmt -- -ci -i 2 -d $files; fi
    @echo "✔ Linting passed!"

# Check all flake outputs evaluate
check:
    @echo -e "\n➤ Evaluating flake"
    @nix run nixpkgs#time -- -f "⏱ Completed in %E" nix flake check "path:$PWD"

# Local quality gate (no switch)
qa:
    @echo -e "\n➤ Running local QA (no switch)…"
    {{JUST}} lint
    {{JUST}} check

# Show the desired, saved preview, and active system/home generations (no build or switch)
status:
    @echo -e "\n➤ Configuration status…"
    @./scripts/status.sh

# Build and compare the system, then save the reviewed generation
preview:
    @echo -e "\n➤ Building system preview…"
    @set -euo pipefail; \
      source scripts/config.sh; source scripts/saved-preview-build.sh; select_system; \
      actual="$(nix build --no-write-lock-file --no-link --print-out-paths "$system_ref.config.system.build.toplevel")"; \
      nix store diff-closures /run/current-system "$actual"; \
      result="$(saved_preview_link system "$NIXOS_CONFIG")"; \
      mkdir -p "$(dirname "$result")"; \
      ln -sfnT "$actual" "$result"; \
      echo "✔ Saved preview: $result"

# Activate exactly the built closure; run `just preview` and review it first
switch:
    @echo -e "\n➤ Switching to saved system preview…"
    @set -euo pipefail; \
      source scripts/config.sh; source scripts/saved-preview-build.sh; select_system; \
      configured_host="$(nix eval --raw --no-write-lock-file "$system_ref.config.networking.hostName")"; \
      current_host="$(hostname)"; \
      test -n "$configured_host" || { echo 'The selected NixOS configuration has no hostname' >&2; exit 1; }; \
      if [ "$current_host" != "$configured_host" ]; then \
        test "${ALLOW_HOST_RENAME:-}" = 1 || { \
          printf 'Host mismatch: running %s, selected %s (%s). To deliberately rename this host, use ALLOW_HOST_RENAME=1 just switch.\n' "$current_host" "$configured_host" "$NIXOS_CONFIG" >&2; exit 1; \
        }; \
        printf 'Opted in to hostname change: %s -> %s\n' "$current_host" "$configured_host"; \
      fi; \
      result="$(saved_preview_link system "$NIXOS_CONFIG")"; \
      actual="$(require_saved_preview_build "$system_ref.config.system.build.toplevel.outPath" "$result" preview)"; \
      sudo nixos-rebuild switch --no-reexec --store-path "$actual"

# Build and compare Home-Manager, then save the reviewed generation
home-preview:
    @echo -e "\n➤ Building Home-Manager preview…"
    @./scripts/home-preview.sh

# Activate only the saved Home-Manager preview; run `just home-preview` first
home-switch:
    @echo -e "\n➤ Switching to saved Home-Manager preview…"
    @./scripts/home-switch.sh

# Switch Home-Manager generation (direct, via nh)
home:
    @echo -e "\n➤ Switching Home-Manager…"
    nh home switch '.?submodules=1' --diff never --no-update-lock-file --no-write-lock-file

# Switch NixOS generation (direct, via nh)
nixos target=host:
    @echo -e "\n➤ Rebuilding NixOS…"
    nh os switch . --hostname {{target}} --diff never --no-update-lock-file --no-write-lock-file

# Fast path: skip pre-activation validation checks
nixos-fast target=host:
    @echo -e "\n➤ Rebuilding NixOS (fast mode)…"
    NH_NO_VALIDATE=1 nh os switch . --hostname {{target}} --diff never --no-update-lock-file --no-write-lock-file --no-nom

# Full pipeline: lint, format, check, then rebuild
all:
    @echo -e "\n➤ Running full pipeline…"
    {{JUST}} lint
    {{JUST}} format
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
# Decrypted file is written to XDG_RUNTIME_DIR (tmpfs) so plaintext never touches disk.
# If interrupted, the OS reclaims tmpfs automatically — no cleanup needed.
sops-edit:
    @echo -e "\n➤ Editing secrets with SOPS…"
    @DEC_FILE="${XDG_RUNTIME_DIR:-/tmp}/secrets-decrypted-$(date +%s).yaml"; \
    sops --decrypt secrets/secrets.yaml > "$DEC_FILE"; \
    echo "Opening editor (close when done)..."; \
    code --wait "$DEC_FILE"; \
    sops --encrypt "$DEC_FILE" > secrets/secrets.yaml; \
    rm -f "$DEC_FILE"; \
    echo "✔ Encrypted and cleaned up!"

# View decrypted secrets (read-only)
sops-view:
    @echo -e "\n➤ Viewing decrypted secrets…"
    sops --decrypt secrets/secrets.yaml

# Decrypt secrets to tmpfs for manual editing
# Decrypted file lives in XDG_RUNTIME_DIR (tmpfs) — never written to persistent disk.
sops-decrypt:
    @echo -e "\n➤ Decrypting secrets to tmpfs…"
    @DEC_FILE="${XDG_RUNTIME_DIR:-/tmp}/secrets-decrypted.yaml"; \
    sops --decrypt secrets/secrets.yaml > "$DEC_FILE"; \
    echo "Decrypted to $DEC_FILE"; \
    echo "Edit the file then run: just sops-encrypt"

# Encrypt file back to secrets
sops-encrypt:
    @echo -e "\n➤ Encrypting decrypted secrets back…"
    @DEC_FILE="${XDG_RUNTIME_DIR:-/tmp}/secrets-decrypted.yaml"; \
    if [ ! -f "$DEC_FILE" ]; then echo "Error: $DEC_FILE not found. Run 'just sops-decrypt' first."; exit 1; fi; \
    sops --encrypt "$DEC_FILE" > secrets/secrets.yaml; \
    rm -f "$DEC_FILE"; \
    echo "✔ Encrypted and cleaned up!"

# Add a single secret (value read from stdin — never leaks to shell history)
# Usage: echo "my_secret_value" | just secrets-add my_key
#    OR: just secrets-add my_key  (then type value, press Enter)
secrets-add key:
    @echo -e "\n➤ Adding secret: {{key}}"
    @echo -n "Enter value (hidden): "; read -rs value; echo; \
    sops --set '["{{key}}"] "'"$value"'"' secrets/secrets.yaml
    @echo "✔ Secret added!"

# Show SOPS public key
sops-key:
    @echo -e "\n➤ SOPS public key:"
    @sops --version && echo ""
    @if [ -f ~/.config/sops/age/keys.txt ]; then \
        echo "Public key:"; \
        nix shell nixpkgs#age -c age-keygen -y ~/.config/sops/age/keys.txt; \
    else \
        echo "No age key found. Create one: nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt"; \
    fi
