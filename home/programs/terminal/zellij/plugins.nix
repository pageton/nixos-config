# Zellij WASM plugin definitions and xdg.configFile entries.

{ pkgs, lib, ... }:

let
  plugins = lib.mapAttrs (_: pkgs.fetchurl) {
    zjstatus = {
      url = "https://github.com/dj95/zjstatus/releases/download/v0.24.0/zjstatus.wasm";
      hash = "sha256-HM7ezh3tYs8+IJvmkM3TnKb7noIo7XGpUfZQf5lWZps=";
    };
    zellij-autolock = {
      url = "https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm";
      hash = "sha256-aclWB7/ZfgddZ2KkT9vHA6gqPEkJ27vkOVLwIEh7jqQ=";
    };
    monocle = {
      url = "https://github.com/imsnif/monocle/releases/download/v0.100.2/monocle.wasm";
      hash = "sha256-TLfizJEtl1tOdVyT5E5/DeYu+SQKCaibc1SQz0cTeSw=";
    };
    room = {
      url = "https://github.com/rvcas/room/releases/download/v1.2.1/room.wasm";
      hash = "sha256-kLSDpAt2JGj7dYYhYFh6BfvtzVwTrcs+0jHwG/nActE=";
    };
    harpoon = {
      url = "https://github.com/Nacho114/harpoon/releases/download/v0.3.0/harpoon.wasm";
      hash = "sha256-f4z1enHx27vRFTN6MWOHgNfhjpuHbe8cgclwGIyqMvI=";
    };
    zellij-forgot = {
      url = "https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm";
      hash = "sha256-MRlBRVGdvcEoaFtFb5cDdDePoZ/J2nQvvkoyG6zkSds=";
    };
    multitask = {
      url = "https://github.com/leakec/multitask/releases/download/v0.44.3_hotfix/multitask.wasm";
      hash = "sha256-ow1Yuzg3S1QrHo+gnamlsB4gdNmqI7B0MYix/2Ge3ho=";
    };
    zellij-attention = {
      url = "https://github.com/KiryuuLight/zellij-attention/releases/download/v0.3.1/zellij-attention.wasm";
      hash = "sha256-QgkzerYacxRI7HMzYvPvaZqQW7tcARKpOm1hY2D9ci8=";
    };
    zellij-worktree = {
      url = "https://github.com/sharph/zellij-worktree/releases/download/v0.1.0/zellij-worktree.wasm";
      hash = "sha256-Ux4vUuZ9vnb1K3xJrX8sk2dYdNe3cRK6rVx+ZPrPH4I=";
    };
  };
in
{
  xdg.configFile = lib.mapAttrs' (name: src: {
    name = "zellij/plugins/${name}.wasm";
    value.source = src;
  }) plugins;
}
