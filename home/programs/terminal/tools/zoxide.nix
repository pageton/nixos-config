# Zoxide (fast directory changer) configuration.

{ lib, ... }:

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh.initContent = lib.mkOrder 500 ''
    export _ZO_DOCTOR=0
  '';
}
