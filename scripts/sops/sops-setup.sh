#!/usr/bin/env bash
# sops-setup.sh - Generate or verify SOPS age key for secrets encryption.
# Usage: ./scripts/sops/sops-setup.sh
set -euo pipefail

AGE_DIR="$HOME/.config/sops/age"
AGE_KEY_FILE="$AGE_DIR/keys.txt"

mkdir -p "$AGE_DIR"
chmod 700 "$AGE_DIR"

if [[ -f "$AGE_KEY_FILE" ]]; then
    echo "✔ Age key already exists at $AGE_KEY_FILE"
    echo ""
    echo "Public key:"
    age-keygen -y "$AGE_KEY_FILE"
    echo ""
    echo "If you need to regenerate, remove $AGE_KEY_FILE and re-run this script."
    exit 0
fi

echo "➤ Generating new age key..."
age-keygen -o "$AGE_KEY_FILE"
chmod 600 "$AGE_KEY_FILE"

echo ""
echo "✔ Age key generated at $AGE_KEY_FILE"
echo ""
echo "Public key:"
age-keygen -y "$AGE_KEY_FILE"
echo ""
echo "Add this public key to .sops.yaml if not already present:"
echo "  keys:"
echo "    - &primary <public-key-above>"
echo "  creation_rules:"
echo "    - path_regex: secrets/secrets\\.yaml$"
echo "      key_groups:"
echo "        - age:"
echo "          - *primary"
