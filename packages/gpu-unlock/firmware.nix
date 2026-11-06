# Firmware blobs for the gpu-unlock kernel module (module build: default.nix).
#
# The module request_firmware()s these at boot from
# lib/firmware/gpu-unlock/610.43.03/ — the names and the 610.43.03 directory
# are compiled into upstream's recipes.c, so they are pinned here too.
#
# Upstream generates the blobs at package-build time by downloading two
# NVIDIA artifacts over HTTPS and running two extraction scripts (firmware/
# in the upstream tree):
#
#   extract_gsp.py         NVIDIA-Linux-x86_64-610.43.03-no-compat32.run
#                          (makeself archive, zstd payload) → GSP images
#   extract_boot_assets.py NVIDIA-kernel-module-source-610.43.03.tar.xz
#                          (generated bindata C sources) → Booter/SEC2 images
#
# The pinned fetchurl inputs below keep that generation inside the Nix
# sandbox. 610.43.03 is not the driver that runs on this system — it is only
# the reference the unlock sequence's Falcon/GSP code is taken from; the
# version is upstream's choice (NV in their Makefile), not ours to bump.
{
  lib,
  stdenv,
  fetchurl,
  python3,
  xz,
  zstd,
  callPackage,
}:

let
  source = callPackage ./source.nix { };
  nvVersion = "610.43.03";

  nvSource = fetchurl {
    url = "https://download.nvidia.com/XFree86/NVIDIA-kernel-module-source/NVIDIA-kernel-module-source-${nvVersion}.tar.xz";
    hash = "sha256-fhGJI8eiPtw2EU1jJzpG4+BOmvmGlaQiA+esLf6fwdw=";
  };

  nvInstaller = fetchurl {
    url = "https://download.nvidia.com/XFree86/Linux-x86_64/${nvVersion}/NVIDIA-Linux-x86_64-${nvVersion}-no-compat32.run";
    hash = "sha256-4IRFHbcwpt8p09dPZVdJxNI248lF99lLUgXoQxj+L5A=";
  };
in
stdenv.mkDerivation {
  pname = "gpu-unlock-firmware";
  version = "${source.version}-${nvVersion}";

  inherit (source) src;

  nativeBuildInputs = [
    python3
    xz # tar -xf of the kernel-module-source .tar.xz input
    zstd # extract_gsp.py shells out to `zstd -dc` for the makeself payload
  ];

  # Upstream's Makefile `firmware` target, minus its network fetch.
  buildPhase = ''
    runHook preBuild
    assets=$NIX_BUILD_TOP/assets
    mkdir -p "$assets" "$NIX_BUILD_TOP/source-unpack"
    tar -xf ${nvSource} -C "$NIX_BUILD_TOP/source-unpack"
    python3 firmware/extract_gsp.py "${nvInstaller}" "$assets"
    python3 firmware/extract_boot_assets.py \
      "$NIX_BUILD_TOP/source-unpack/NVIDIA-kernel-module-source-${nvVersion}" "$assets"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    outDir=$out/lib/firmware/gpu-unlock/${nvVersion}
    install -d "$outDir"
    install -m644 "$NIX_BUILD_TOP/assets"/*.bin -t "$outDir"
    # Upstream's install-firmware ships exactly 16 blobs; the initrd file
    # list in nixos/modules/gpu-unlock.nix mirrors it by name. Fail loudly
    # here instead of shipping a broken initrd when upstream changes the set.
    count=$(ls "$outDir" | wc -l)
    if [ "$count" -ne 16 ]; then
      echo "gpu-unlock-firmware: expected 16 blobs, got $count:" >&2
      ls "$outDir" >&2
      exit 1
    fi
    install -Dm644 "$NIX_BUILD_TOP/assets/NVIDIA-LICENSE" \
      $out/share/doc/gpu-unlock-firmware/NVIDIA-LICENSE
    install -Dm644 firmware/NOTICE.md \
      $out/share/doc/gpu-unlock-firmware/NOTICE.md
    runHook postInstall
  '';

  meta = {
    description = "Firmware assets for the gpu-unlock kernel module, extracted from the pinned NVIDIA 610.43.03 inputs";
    homepage = "https://github.com/Zagitta/gpu-unlock";
    license = lib.licenses.gpl2Only;
    # NVIDIA firmware blobs themselves stay under NVIDIA's terms (upstream
    # firmware/NOTICE.md + NVIDIA-LICENSE installed into share/doc).
    maintainers = [ ];
    platforms = lib.platforms.linux;
  };
}
