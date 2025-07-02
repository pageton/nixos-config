{ pkgs, ... }:

{
  programs.nix-ld = {
    enable = true;

    libraries = with pkgs; [
      stdenv.cc.cc # glibc + compiler runtime
      libgcc
      zlib
      openssl
    ];
  };
}
