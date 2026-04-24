{
  programs.nvf.settings.vim.languages = {
    enableDAP = true;
    enableExtraDiagnostics = true;
    enableFormat = true;
    enableTreesitter = true;

    rust.enable = true;
    go = {
      enable = true;
      extraDiagnostics.enable = false;
    };
    clang.enable = true;
    python.enable = true;
    markdown = {
      enable = true;
      format.enable = false;
      extensions.markview-nvim.enable = true;
      extraDiagnostics.enable = true;
    };
    ts = {
      enable = true;
      extensions.ts-error-translator.enable = true;
    };
    css.enable = true;
    svelte.enable = true;
    html.enable = true;
    bash.enable = true;
    nix.enable = true;
    lua.enable = true;
  };
}
