{ lib, pkgs, ... }:
{
  programs.nvf.settings.vim = {
    diagnostics = {
      enable = true;
      config = {
        signs = {
          text = {
            # Intentionally blank — rely on sign highlight color only, not text
            "vim.diagnostic.severity.Error" = " ";
            "vim.diagnostic.severity.Warn" = " ";
            "vim.diagnostic.severity.Hint" = " ";
            "vim.diagnostic.severity.Info" = " ";
          };
        };
        underline = true;
        update_in_insert = false; # avoid LSP slowdown in large files during typing
        virtual_text = true;
      };
      nvim-lint.enable = true;
    };

    syntaxHighlighting = true;

    treesitter = {
      enable = true;
      autotagHtml = true;
      context.enable = true;
      highlight.enable = true;
      # Extra grammars beyond what language modules install
      grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        latex
        typst
        scss
        vue
      ];
    };

    lsp = {
      enable = true;
      trouble.enable = true;
      lspSignature.enable = true;
      lspconfig.enable = true;
      formatOnSave = true;
      inlayHints.enable = true;
      null-ls.enable = true;

      servers.nil.settings.nil.nix.autoArchive = true;
      servers.gopls = {
        single_file_support = false; # gopls requires a go.mod — disables LSP for standalone .go files
        settings = {
          gopls = {
            analyses = {
              unusedparams = true;
              shadow = false;
              unusedwrite = true;
              unusedvariable = true;
              ST1000 = false;
            };
            staticcheck = true;
            gofumpt = true;
            codelenses = {
              generate = true;
              regenerate_cgo = true;
              run_govulncheck = false;
              test = true;
              tidy = true;
              upgrade_dependency = true;
              vendor = true;
            };
            usePlaceholders = true;
            completeFunctionCalls = true;
            semanticTokens = true;
            directoryFilters = [
              "-**/vendor"
              "-**/node_modules"
            ];
          };
        };
      };

      otter-nvim = {
        enable = true;
        setupOpts = {
          buffers.set_filetype = true;
          lsp.diagnostic_update_event = [
            "BufWritePost"
            "InsertLeave"
          ];
        };
      };

      lspkind.enable = true;

      lspsaga = {
        enable = true;
        setupOpts = {
          ui.code_action = "";
          lightbulb = {
            sign = false;
            virtual_text = true;
          };
          breadcrumbs.enable = false;
        };
      };

      presets.tailwindcss-language-server.enable = true;
    };

    formatter.conform-nvim.enable = true;
  };
}
