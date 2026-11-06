# Pin the @estebanforge/pi-antigravity-bridge Pi package as an immutable
# local extension instead of a mutable npm install (`pi update --extensions`).
#
# The npm tarball ships sources without a lockfile; the lock committed next to
# this expression was generated for the exact published package.json with
# `npm install --package-lock-only --legacy-peer-deps` (legacy mode keeps the
# host-provided @earendil-works/* peer out of the tree — Pi injects those at
# runtime and a physical copy would shadow its module mapping).
{
  pkgs,
}:
pkgs.buildNpmPackage {
  pname = "pi-antigravity-bridge";
  version = "1.9.0";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@estebanforge/pi-antigravity-bridge/-/pi-antigravity-bridge-1.9.0.tgz";
    hash = "sha256-0emklTT5LuxkoHkhIBSVUAO/79LmR0DhDlBG5yQap88=";
  };

  postPatch = ''
    cp ${./extensions/antigravity-bridge/package-lock.json} package-lock.json
    cp ${./extensions/antigravity-bridge/index.ts} index.ts
  '';

  npmDepsHash = "sha256-NTUrLLzJQKv4qmFPVZMLGjG+Z/e/ihXDUKk3mUxQJdA=";
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r package.json index.ts extensions src node_modules "$out/"
    runHook postInstall
  '';

  meta = {
    description = "Pi package bridging the Antigravity (Gemini) CLI as provider, tools, and commands";
    homepage = "https://www.npmjs.com/package/@estebanforge/pi-antigravity-bridge";
    license = pkgs.lib.licenses.mit;
    platforms = pkgs.lib.platforms.unix;
  };
}
