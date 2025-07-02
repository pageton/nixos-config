set shell := ["/usr/bin/env", "bash", "-c"]
set quiet

# a little helper so we always call the same Justfile
JUST := "just -u -f " + justfile()

header := "Available tasks:\n"

_default:
    @{{JUST}} --list-heading "{{header}}" --list

# ────────────────────────────────────────────────────────────────────────────────
# Format all .nix files
format:
    @echo -e "\n➤ Formatting Nix files…"
    find . -type f -name '*.nix' -exec nixfmt {} +

# Lint all .nix files
lint:
    @echo -e "\n➤ Linting Nix files…"
    nix run nixpkgs#statix -- check .
    @echo "✔ Linting passed!"

# Check all missing imports
modules:
    @echo -e "\n➤ Checking modules…"
    bash modules-check.sh

# Switch Home-Manager generation
home:
    @echo -e "\n➤ Switching Home-Manager…"
    home-manager switch --flake .

# Switch NixOS generation
nixos:
    @echo -e "\n➤ Rebuilding NixOS…"
    sudo nixos-rebuild switch --flake .

update:
    nix flake update

# All of the above, in order
all:
    @echo -e "\n➤ Running full pipeline…"
    {{JUST}} modules
    {{JUST}} lint
    {{JUST}} format
    {{JUST}} nixos
    {{JUST}} home
    @echo -e "✅ All done!"
