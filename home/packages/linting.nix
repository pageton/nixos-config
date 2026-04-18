# CLI linting and formatting tools (not LSP servers).
# Editor-facing LSP servers live in programs/languages/lsp-servers.nix.
{ pkgsStable, ... }:
with pkgsStable;
[
  markdownlint-cli # Markdown linting (used by nvim-lint)
]
