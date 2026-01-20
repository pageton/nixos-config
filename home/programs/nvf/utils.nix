{
  pkgs,
  lib,
  ...
}: {
  programs.nvf.settings.vim = {
    undoFile.enable = true;
    utility = {
      vim-wakatime.enable = true;
      motion.flash-nvim.enable = true;
      outline.aerial-nvim.enable = true;
    };
    tabline.nvimBufferline.enable = true;
    notes.todo-comments.enable = true;
    assistant = {
      neocodeium = {
        enable = true;
        keymaps.accept = "<A-Tab>";
      };
    };
    statusline.lualine.enable = true;

    autocomplete.nvim-cmp = {
      enable = true;

      sources = {
        nvim_lsp = lib.mkForce "[LSP]";
        luasnip = lib.mkForce "[Snip]";
        buffer = "[Buffer]";
        path = "[Path]";
      };

      setupOpts = {
        snippet = {
          expand = lib.generators.mkLuaInline ''
            function(args)
              require("luasnip").lsp_expand(args.body)
            end
          '';
        };
        mapping = lib.generators.mkLuaInline ''
          require("cmp").mapping.preset.insert({
            ["<C-k>"] = require("cmp").mapping.select_prev_item(),
            ["<C-j>"] = require("cmp").mapping.select_next_item(),
            ["<Tab>"] = require("cmp").mapping.select_next_item(),
            ["<C-b>"] = require("cmp").mapping.scroll_docs(-4),
            ["<C-f>"] = require("cmp").mapping.scroll_docs(4),
            ["<C-e>"] = require("cmp").mapping.abort(),
            ["<CR>"] = require("cmp").mapping.confirm({ select = false }),
          })
        '';
        formatting = {
          format = lib.generators.mkLuaInline ''
            require("lspkind").cmp_format({
              mode = "symbol",
              maxwidth = 50,
              ellipsis_char = "...",
            })
          '';
        };
        completion = {
          completeopt = "menu,menuone,preview,noselect";
        };
      };

      sourcePlugins = [
        pkgs.vimPlugins.cmp-cmdline
        pkgs.vimPlugins.cmp-nvim-lsp
        pkgs.vimPlugins.cmp-buffer
        pkgs.vimPlugins.cmp-path
        pkgs.vimPlugins.cmp_luasnip
      ];
    };

    luaConfigRC.cmp-cmdline = ''
      require("luasnip.loaders.from_vscode").lazy_load()

      -- Command-line setup - setup after cmp is fully loaded
      vim.defer_fn(function()
        local ok, cmp = pcall(require, "cmp")
        if ok then
          cmp.setup.cmdline(":", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
              { name = "cmdline" }
            }, {
              { name = "path" }
            })
          })
          cmp.setup.cmdline("/", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
              { name = "buffer" }
            }
          })
        else
          vim.notify("cmp not ready yet, retrying...", vim.log.levels.WARN)
        end
      end, 100)

      -- Auto organize imports on save for Go
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.go",
        callback = function()
          local params = vim.lsp.util.make_range_params()
          params.context = {only = {"source.organizeImports"}}
          local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)
          for cid, res in pairs(result or {}) do
            for _, r in pairs(res.result or {}) do
              if r.edit then
                local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
                vim.lsp.util.apply_workspace_edit(r.edit, enc)
              end
            end
          end
        end,
      })

      -- Auto organize imports on save for TypeScript/JavaScript
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.{ts,tsx,js,jsx}",
        callback = function()
          vim.lsp.buf.code_action({
            context = {only = {"source.organizeImports"}},
            apply = true,
          })
        end,
      })
    '';

    snippets.luasnip.enable = true;

    ui = {
      noice.enable = true;
      colorizer.enable = true;
    };

    git = {
      enable = true;
      gitsigns.enable = true;
    };

    terminal.toggleterm = {
      enable = true;
      lazygit = {
        enable = true;
        mappings.open = "<leader>gl";
      };
    };

    visuals = {
      rainbow-delimiters.enable = true;
      nvim-scrollbar.enable = false;
    };

    comments.comment-nvim = {
      enable = true;
      mappings = {
        toggleCurrentLine = "<C-_>";
      };
    };
  };
}
