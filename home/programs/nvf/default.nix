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
      luaPackages = [ "jsregexp" ]; # required by LuaSnip for regex match nodes
      startPlugins = [
        pkgs.vimPlugins.vim-tmux-navigator
        pkgs.vimPlugins.vim-wakatime
        pkgs.vimPlugins.catppuccin-nvim # theme override via options.nix
      ];
    };
  };
}
