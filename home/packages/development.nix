{ pkgs, pkgsStable }:

(with pkgsStable; [
  gcc
  cmake
])

++ (with pkgs; [
  rustc
  cargo
  go
  sqlite
  just
  bun
  nodejs
  air
  python311
  python311Packages.pip
  gopls
  golines
  goimports-reviser
  gofumpt
  lua-language-server
])
