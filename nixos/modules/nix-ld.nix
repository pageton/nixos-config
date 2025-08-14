# Nix-ld configuration for running non-Nix binaries.

{ pkgsStable, ... }:

{
  programs.nix-ld = {
    enable = true;

    libraries = with pkgsStable; [
      stdenv.cc.cc # glibc + compiler runtime
      libgcc
      zlib
      openssl
    ];
  };
}
