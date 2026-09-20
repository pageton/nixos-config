# Mojo programming language (Modular).
# No nixpkgs package exists (NixOS/nixpkgs#257274 closed "not planned"); Mojo 1.x
# ships as a PyPI wheel, so it is installed with `uv tool` (uv comes from
# python.nix). Its binaries live in ~/.local/share/uv/tools/mojo/bin; uv only
# shims the console entry points (mojo-lsp-server, mojo-lldb, lldb-*, gpu-query)
# into ~/.local/bin, so `mojo` itself is exposed via a managed wrapper below.
#
# NixOS-specific gotchas handled in activation:
# - The wheel ships `mojo` as a top-level venv script, not a console entry
#   point, so uv does not shim it. The driver also locates its crashpad
#   handler via PATH, and the venv bin is not on the user PATH — the wrapper
#   below solves both.
# - Mojo's linker assumes a system libstdc++ at runtime (Ubuntu-style). NixOS
#   has no /usr/lib/libstdc++.so.6, so the nixpkgs one is linked into the SDK
#   lib dir, which every built binary already carries in its RUNPATH (SDK libs
#   use $ORIGIN RPATH, so their indirect needs resolve too).

{
  config,
  lib,
  pkgs,
  ...
}:

let
  mkShellAliasPrograms = import ../../_helpers/_shell-alias-programs.nix;
in
{
  programs = mkShellAliasPrograms {
    shellAliases = {
      mojor = "mojo run";
      mojob = "mojo build";
      mojof = "mojo format";
    };
  };

  home = {
    # Wrapper (not symlink): prepends the uv tool venv bin to PATH so the
    # driver can locate modular-crashpad-handler (it searches PATH — the venv
    # bin is not on the user PATH, which spams a crashpad warning on every
    # `mojo run`/`build`), and execs the real venv script so argv[0] stays
    # the venv path for any argv[0]-relative lookups.
    file.".local/bin/mojo" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        mojo_venv_bin="${config.home.homeDirectory}/.local/share/uv/tools/mojo/bin"
        export PATH="$mojo_venv_bin:$PATH"
        exec "$mojo_venv_bin/mojo" "$@"
      '';
    };

    activation.installMojo = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Install-once: a compiler toolchain must not silently change versions on
      # every home switch. Upgrade deliberately with `uv tool upgrade mojo`.
      mojo_venv_bin="$HOME/.local/share/uv/tools/mojo/bin"
      if [[ ! -x "$mojo_venv_bin/mojo" ]]; then
        echo "Installing Mojo (uv tool)..."
        $DRY_RUN_CMD ${lib.getExe pkgs.uv} tool install mojo
      fi

      # Runtime libstdc++ for compiled Mojo binaries (see header comment).
      # Re-applied on every switch: `uv tool` reinstalls recreate the venv.
      for mojo_modular_lib in "$mojo_venv_bin"/../lib/python3.*/site-packages/modular/lib; do
        [[ -d "$mojo_modular_lib" ]] || continue
        $DRY_RUN_CMD ln -sfn "${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6" "$mojo_modular_lib/libstdc++.so.6"
      done
    '';
  };
}
