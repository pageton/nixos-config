# Pinned upstream source shared by the kernel module (default.nix) and the
# firmware generator (firmware.nix).
#
# Upstream publishes no release tags — main moves. The commit is pinned by
# full revision; the version is cross-checked at build time by upstream's own
# `make install-dkms` (dkms.conf PACKAGE_VERSION vs main.c MODULE_VERSION).
{ fetchFromGitHub }:

rec {
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "Zagitta";
    repo = "gpu-unlock";
    rev = "7eb51bccae0a0b7e599e084d971170e9a1e82d0c";
    hash = "sha256-1KD/J1S1uyI5GGoTwQ1cU/sXeEKlG54exSvi6U+j73M=";
  };
}
