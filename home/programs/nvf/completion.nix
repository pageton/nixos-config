{ pkgs, lib, ... }:
{
  programs.nvf.settings.vim.autocomplete.nvim-cmp = {
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
          ["<Tab>"] = require("cmp").mapping.select_next_item(),
          ["<S-Tab>"] = require("cmp").mapping.select_prev_item(),
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

  programs.nvf.settings.vim.luaConfigRC.cmp-cmdline = ''
    require("luasnip.loaders.from_vscode").lazy_load()

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
        local file_size = vim.fn.getfsize(vim.fn.expand("%:p"))
        if file_size > 500000 then return end

        local clients = vim.lsp.get_clients({ bufnr = 0, name = "gopls" })
        if #clients == 0 then return end

        local client = clients[1]
        local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
        params.context = {only = {"source.organizeImports"}}
        local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
        for cid, res in pairs(result or {}) do
          for _, r in pairs(res.result or {}) do
            if r.edit then
              local c = vim.lsp.get_client_by_id(cid)
              vim.lsp.util.apply_workspace_edit(r.edit, c and c.offset_encoding or "utf-16")
            end
          end
        end
      end,
    })

    -- Auto organize imports on save for TypeScript/JavaScript
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
      callback = function()
        vim.lsp.buf.code_action({
          context = {only = {"source.organizeImports"}},
          apply = true,
        })
      end,
    })
  '';
}
