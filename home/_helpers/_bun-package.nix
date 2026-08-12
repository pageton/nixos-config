# Shared Bun runtime pinned to 1.3.14 — tested working with omp/copilot CLIs.
# Pinned because these CLIs are sensitive to Bun version changes.
# Import: bunPackage = import ../../_helpers/_bun-package.nix { inherit pkgs; };
{ pkgs }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "bun-bin";
  version = "1.3.14";

  src = pkgs.fetchzip {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.14/bun-linux-x64.zip";
    hash = "sha256-YyGDD7f0JlmiO2G3LY80p/oMUpWXcoC7x7LW/gU/LmU=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src/bun-linux-x64/bun" "$out/bin/bun"
    ln -s bun "$out/bin/bunx"
    runHook postInstall
  '';

  meta = pkgs.bun.meta // {
    mainProgram = "bun";
  };
}
