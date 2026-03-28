{
  lib,
  pkgs,
  ...
}:
{
  programs.nvf.settings.vim = {
    diagnostics = {
      enable = true;
      config = {
        signs = {
          text = {
            "vim.diagnostic.severity.Error" = " ";
            "vim.diagnostic.severity.Warn" = " ";
            "vim.diagnostic.severity.Hint" = " ";
            "vim.diagnostic.severity.Info" = " ";
          };
        };
        underline = true;
        update_in_insert = true;
        virtual_text = {
          format = lib.generators.mkLuaInline /* lua */ ''
            function(diagnostic)
              return string.format("%s", diagnostic.message)
              --return string.format("%s (%s)", diagnostic.message, diagnostic.source)
            end
          '';
        };
      };
      nvim-lint = {
        enable = true;
      };
    };
    syntaxHighlighting = true;
    treesitter = {
      enable = true;
      autotagHtml = true;
      context.enable = true;
      highlight.enable = true;
      grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        typescript # in language settings only tsx gets enabled, not typescript
        latex # for snacks.image LaTeX rendering
        typst # for snacks.image Typst rendering
        scss # for snacks.image SCSS support
        vue # for snacks.image Vue support
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
        single_file_support = false;
        settings = {
          gopls = {
            analyses = {
              unusedparams = true;
              shadow = false;
              unusedwrite = true;
              unusedvariable = true;
              ST1000 = false; # disable "package comment" requirement
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
          lsp = {
            diagnostic_update_event = [
              "BufWritePost"
              "InsertLeave"
            ];
          };
        };
      };
      lspkind.enable = true;
      lspsaga = {
        enable = true;
        setupOpts = {
          ui = {
            code_action = "";
          };
          lightbulb = {
            sign = false;
            virtual_text = true;
          };
          breadcrumbs.enable = false;
        };
      };
    };
    languages = {
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
        extensions = {
          markview-nvim = {
            enable = true;
          };
        };
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
      tailwind.enable = true;
    };
    formatter = {
      conform-nvim = {
        enable = true;
      };
    };
  };
}
