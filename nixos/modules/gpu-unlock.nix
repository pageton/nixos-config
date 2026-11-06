# gpu-unlock: removes NVIDIA's half-rate tensor-core cap (FP16/BF16/TF32 with
# FP32 accumulation) on GeForce RTX 20/30/40 cards at boot, before the stock
# nvidia driver binds. This host's RTX 3070 (Ampere, PCI 0000:01:00.0) is
# upstream's stable compatibility tier.
#
# Flow: stage 1 modprobes gpu_unlock from the initrd (nvidia is not in the
# initrd on this host, so the card is guaranteed unbound), the module runs
# the unlock + FLR, and stage 2's udev then loads nvidia, which binds an
# already-unlocked card. The firmware blobs land in the initrd automatically:
# make-modules-closure copies every MODULE_FIRMWARE-declared file of each
# boot.initrd.kernelModules entry out of hardware.firmware. Re-unlock after
# suspend is handled by the module's own PM notifier, which runs ahead of
# nvidia's on current drivers. Side effect: the boot console goes blank from
# the FLR until nvidia-drm takes over in stage 2.
#
# Thinkpad note: deliberately NOT in profiles/common.nix — its PRIME-offload
# dGPU runtime-suspends to 0 W, which powers the card down and silently
# resets the unlock (upstream: laptops "expect mixed results").
{
  config,
  lib,
  pkgs,
  ...
}:

let
  firmware = pkgs.callPackage ../../packages/gpu-unlock/firmware.nix { };
in
{
  boot = {
    # Out-of-tree module built against the kernel pinned in boot.nix.
    extraModulePackages = [ (config.boot.kernelPackages.callPackage ../../packages/gpu-unlock { }) ];

    # Load in stage 1 so the unlock always precedes nvidia's stage-2 bind —
    # upstream deliberately ships no `softdep nvidia pre:` rule (kmod only
    # honours the first softdep line it reads, so it would be fragile).
    initrd.kernelModules = [ "gpu_unlock" ];

    # Opt-in: the module does nothing without this. `all` unlocks every
    # supported unbound card; other NVIDIA generations and non-NVIDIA GPUs
    # (this host's AMD iGPU) are logged and skipped.
    kernelParams = [ "gpu_unlock.targets=all" ];
  };

  # Source of the MODULE_FIRMWARE blobs the initrd closure copies per-module.
  hardware.firmware = [ firmware ];
}
