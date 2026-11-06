# gpu-unlock kernel module (https://github.com/Zagitta/gpu-unlock).
#
# Removes NVIDIA's half-rate cap on FP16/BF16/TF32 tensor math (FP32
# accumulation) for GeForce RTX 20/30/40 cards: loaded before the stock
# `nvidia` driver binds, it runs the unlock sequence (CMP V67/PLM technique),
# writes the full-rate speed selectors and performs an FLR. No patched
# driver, no VBIOS flash, nothing to redo on driver updates. The module is
# inert unless `gpu_unlock.targets=` is on the kernel command line.
#
# Built as an out-of-tree module for whichever kernel the caller's callPackage
# scope injects (nixos/modules/gpu-unlock.nix uses boot.kernelPackages).
# The matching firmware blobs come from firmware.nix and must be in the
# initrd when the module loads.
{
  lib,
  stdenv,
  kernel,
  kernelModuleMakeFlags,
  callPackage,
}:

let
  source = callPackage ./source.nix { };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gpu-unlock";
  version = "${source.version}-${kernel.modDirVersion}";

  inherit (source) src;

  # kernelModuleMakeFlags carries Kbuild-escaped values (cmd_sign uses
  # $(space)); structured attrs keep each flag one argv entry verbatim.
  __structuredAttrs = true;
  strictDeps = true;
  enableParallelBuilding = true;

  nativeBuildInputs = kernel.moduleBuildDependencies;
  hardeningDisable = [ "pic" ];

  makeFlags = kernelModuleMakeFlags ++ [ "KERNELRELEASE=${kernel.modDirVersion}" ];

  # Upstream's kernel/gpu_unlock/Makefile is a thin wrapper
  # (`make KDIR=...` → `$(MAKE) -C $KDIR M=$CURDIR modules`) that cannot
  # carry kernelModuleMakeFlags — invoke kbuild directly, the way nixpkgs'
  # own external modules do.
  buildPhase = ''
    runHook preBuild
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M=$(pwd)/kernel/gpu_unlock "''${makeFlags[@]}"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    # kernelModuleMakeFlags already sets DEPMOD=true + INSTALL_MOD_STRIP=1,
    # so this only places the .ko under lib/modules/<ver>/extra/.
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M=$(pwd)/kernel/gpu_unlock "''${makeFlags[@]}" \
      INSTALL_MOD_PATH=${placeholder "out"} modules_install
    runHook postInstall
  '';

  meta = {
    description = "Full-speed tensor cores for GeForce RTX 20/30/40 — kernel module";
    homepage = "https://github.com/Zagitta/gpu-unlock";
    license = lib.licenses.gpl2Only;
    maintainers = [ ];
    platforms = lib.platforms.linux;
  };
})
