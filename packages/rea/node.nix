# Repack the official REA-compatible Node binary without compiling Node/V8.
#
# The upstream linux-x64 tarball binary is left unpatched: on this Nixpkgs pin,
# patchelf --set-interpreter on Node 24's main binary reliably corrupts it
# (SIGSEGV before main). Instead, bin/{node,npm,npx} are wrapper scripts that
# execute the official binary through the store's dynamic loader with the
# required runtime libraries — the invocation verified to work on this
# workstation.
{ pkgs }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "nodejs-rea-bin";
  version = "24.22.1";
  src = pkgs.fetchurl {
    url = "https://nodejs.org/dist/v24.22.1/node-v24.22.1-linux-x64.tar.xz";
    # Verified against the signed upstream SHASUMS256.txt release manifest.
    hash = "sha256-bBcqmrZxj3uAH7WnvUhq8u5eMnWAhqBLhPzOKqdwleY=";
  };
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;
  installPhase = ''
    runHook preInstall
    tree="$out/lib/nodejs-rea-bin"
    mkdir -p "$tree" "$out/bin"
    cp -r bin include lib share LICENSE CHANGELOG.md README.md "$tree/"
    # process.execPath and env-node resolve to the loader wrapper, while the
    # official binary itself keeps a distinct, loop-free name.
    mv "$tree/bin/node" "$tree/bin/node.bin"
    writeNodeWrapper() {
      entry=""
      if [ -n "$1" ]; then entry="\"$tree/$1\""; fi
      {
        echo '#!${pkgs.runtimeShell}'
        echo 'export LD_LIBRARY_PATH=${
          pkgs.lib.makeLibraryPath [ (pkgs.lib.getLib pkgs.stdenv.cc.cc) ]
        }'
        echo "exec ${pkgs.stdenv.cc.bintools.dynamicLinker} \"$tree/bin/node.bin\" $entry \"\$@\""
      } > "$2"
      chmod +x "$2"
    }
    writeNodeWrapper "" "$out/bin/node"
    writeNodeWrapper lib/node_modules/npm/bin/npm-cli.js "$out/bin/npm"
    writeNodeWrapper lib/node_modules/npm/bin/npx-cli.js "$out/bin/npx"
    ln -sf "$out/bin/node" "$tree/bin/node"
    ln -sf "$out/bin/npm" "$tree/bin/npm"
    ln -sf "$out/bin/npx" "$tree/bin/npx"
    runHook postInstall
  '';
  meta = {
    description = "Official Node.js runtime for pinned REA, run through the store loader";
    homepage = "https://nodejs.org/";
    license = pkgs.lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "node";
  };
}
