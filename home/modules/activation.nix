{
  config,
  lib,
  ...
}:
{
  home.activation.installPackages = lib.mkForce (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      function nixReplaceProfile() {
        local oldNix="$(command -v nix)"

        nixProfileRemove 'home-manager-path'

        run $oldNix profile add $1
      }

      if [[ -e ${config.home.profileDirectory}/manifest.json ]] ; then
        INSTALL_CMD="nix profile add"
        INSTALL_CMD_ACTUAL="nixReplaceProfile"
        LIST_CMD="nix profile list"
        REMOVE_CMD_SYNTAX='nix profile remove {number | store path}'
      else
        INSTALL_CMD="nix-env -i"
        INSTALL_CMD_ACTUAL="run nix-env -i"
        LIST_CMD="nix-env -q"
        REMOVE_CMD_SYNTAX='nix-env -e {package name}'
      fi

      if ! $INSTALL_CMD_ACTUAL ${config.home.path} ; then
        echo
        _iError $'Oops, Nix failed to install your new Home Manager profile!\n\nPerhaps there is a conflict with a package that was installed using\n"%s"? Try running\n\n    %s\n\nand if there is a conflicting package you can remove it with\n\n    %s\n\nThen try activating your Home Manager configuration again.' "$INSTALL_CMD" "$LIST_CMD" "$REMOVE_CMD_SYNTAX"
        exit 1
      fi
      unset -f nixReplaceProfile
      unset INSTALL_CMD INSTALL_CMD_ACTUAL LIST_CMD REMOVE_CMD_SYNTAX
    ''
  );
}
