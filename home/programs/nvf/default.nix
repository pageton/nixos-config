# NVF is a Neovim configuration that provides a minimal setup with essential plugins and configurations.
{ inputs, pkgs, ... }:
{
  imports = [
    inputs.nvf.homeManagerModules.default
    ./options.nix
    ./languages.nix
    ./picker.nix
    ./snacks.nix
    ./bindings.nix
    ./utils.nix
    ./mini.nix
  ];

  programs.nvf = {
    enable = true;
    settings.vim = {
      startPlugins = [
        pkgs.vimPlugins.vim-tmux-navigator
        pkgs.vimPlugins.vim-wakatime
        pkgs.vimPlugins.catppuccin-nvim
      ];
    };
  };
}
