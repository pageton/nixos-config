{ inputs, system, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
    package = inputs.neovim-nightly-overlay.packages.${system}.neovim;
  };
  xdg.configFile."nvim".source = /home/sadiq/System/home/programs/neovim;
}
