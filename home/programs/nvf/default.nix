# NVF — Neovim configuration via Nix.
{ inputs, pkgs, ... }:
{
  imports = [
    inputs.nvf.homeManagerModules.default
    ./options.nix
    ./lsp.nix
    ./languages.nix
    ./completion.nix
    ./snacks.nix
    ./bindings.nix
    ./utils.nix
    ./mini.nix
  ];

  programs.nvf = {
    enable = true;
    settings.vim = {
      luaPackages = [ "jsregexp" ];
      startPlugins = [
        pkgs.vimPlugins.vim-tmux-navigator
        pkgs.vimPlugins.vim-wakatime
        pkgs.vimPlugins.catppuccin-nvim
      ];
    };
  };
}
