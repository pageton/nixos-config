{ pkgs, lib, ... }:
{
  programs.nvf.settings.vim = {
    utility = {
      vim-wakatime.enable = true;
      motion.flash-nvim.enable = true;
      outline.aerial-nvim.enable = true;
    };

    tabline.nvimBufferline.enable = true;
    notes.todo-comments.enable = true;
    statusline.lualine.enable = true;

    assistant = {
      neocodeium = {
        enable = true;
        keymaps.accept = "<A-Tab>";
      };
    };

    comments.comment-nvim = {
      enable = true;
      mappings = {
        toggleCurrentLine = "<C-/>";
      };
    };

    ui = {
      noice = {
        enable = true;
        setupOpts.lsp.signature.enabled = true;
      };
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

    undoFile.enable = true;

    # Fix keymap overlaps (runs after NVF sets up all keymaps)
    luaConfigRC.keymap-fixes = ''
      -- Remap gitsigns toggle_deleted from <leader>td to <leader>tD
      -- to free <leader>td prefix for todo-comments (<leader>tdt, <leader>tdq)
      vim.schedule(function()
        pcall(vim.keymap.del, "n", "<leader>td")
        vim.keymap.set("n", "<leader>tD", function()
          package.loaded.gitsigns.toggle_deleted()
        end, { desc = "Toggle deleted [Gitsigns]", silent = true })
      end)

      -- Remove Neovim 0.11 built-in LSP keymaps that conflict with user keymaps
      vim.schedule(function()
        pcall(vim.keymap.del, "n", "grr")
        pcall(vim.keymap.del, "n", "gra")
      end)
    '';
  };
}
