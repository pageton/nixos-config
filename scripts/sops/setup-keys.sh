#!/usr/bin/env bash
# setup-keys.sh - Extract SSH and GPG keys from SOPS secrets into the filesystem.
# Requires: SOPS age key configured (run sops-setup.sh first) and NixOS activated
# so that /run/secrets/ is populated.
set -euo pipefail

SECRETS_DIR="/run/secrets"

# Check that SOPS secrets are decrypted and available
if [[ ! -d "$SECRETS_DIR" ]]; then
    echo "Error: SOPS secrets not available at $SECRETS_DIR" >&2
    echo "Run 'just nixos' to activate secrets, then retry." >&2
    exit 1
fi

setup_gpg() {
    local gpg_dir="$HOME/.gnupg"
    mkdir -p "$gpg_dir"
    chmod 700 "$gpg_dir"

    if [[ -f "$SECRETS_DIR/gpg-private-key" ]]; then
        echo "➤ Importing GPG private key..."
        gpg --batch --import "$SECRETS_DIR/gpg-private-key" 2>/dev/null || true
        echo "✔ GPG private key imported"
    else
        echo "⚠ No gpg-private-key secret found, skipping"
    fi
}

setup_ssh() {
    local ssh_dir="$HOME/.ssh"
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    if [[ -f "$SECRETS_DIR/ssh-private-key" ]]; then
        local target="$ssh_dir/id_ed25519"
        cp "$SECRETS_DIR/ssh-private-key" "$target"
        chmod 600 "$target"
        echo "✔ SSH private key installed to $target"
    else
        echo "⚠ No ssh-private-key secret found, skipping"
    fi

    if [[ -f "$SECRETS_DIR/ssh-public-key" ]]; then
        local target="$ssh_dir/id_ed25519.pub"
        cp "$SECRETS_DIR/ssh-public-key" "$target"
        chmod 644 "$target"
        echo "✔ SSH public key installed to $target"
    fi
}

setup_gpg
setup_ssh

echo ""
echo "✔ All keys set up."
