{
  programs.nvf.settings.vim = {
    globals.mapleader = " ";
    binds = {
      whichKey = {
        enable = true;
        # TODO: registers
        register = {};
      };
    };
    keymaps = [
      # General Mappings
      {
        key = "jk";
        mode = "i";
        silent = true;
        action = "<ESC>";
        desc = "Switch to Normal mode";
      }
      {
        key = "<leader>w";
        mode = "n";
        action = ":write<CR>";
        desc = "Write current file";
      }
      {
        key = "<leader>q";
        mode = "n";
        action = ":quit<CR>";
        desc = "Quit";
      }
      {
        key = "<leader>nh";
        mode = "n";
        action = ":nohl<CR>";
        silent = true;
      }
      {
        key = "s";
        mode = "n";
        silent = true;
        action = "<cmd>lua require('flash').jump()<cr>";
        desc = "Flash";
      }
      {
        key = "K";
        mode = "n";
        silent = true;
        action = "<cmd>lua vim.lsp.buf.hover()<cr>";
        desc = "LSP Hover";
      }
      {
        key = "<C-]>";
        mode = "n";
        silent = true;
        action = "<cmd>bnext<cr>";
        desc = "Next Buffer";
      }
      {
        key = "<C-w>";
        mode = "n";
        silent = true;
        action = "<cmd>bdelete<cr>";
        desc = "Delete Buffer";
      }
      {
        key = "<C-[>";
        mode = "n";
        silent = true;
        action = "<cmd>bprev<cr>";
        desc = "Prev Buffer";
      }

      # Tmux navigator
      {
        key = "<C-h>";
        mode = "n";
        silent = true;
        action = "<cmd>TmuxNavigateLeft<cr>";
      }
      {
        key = "<C-j>";
        mode = "n";
        silent = true;
        action = "<cmd>TmuxNavigateDown<cr>";
      }
      {
        key = "<C-k>";
        mode = "n";
        silent = true;
        action = "<cmd>TmuxNavigateUp<cr>";
      }
      {
        key = "<C-l>";
        mode = "n";
        silent = true;
        action = "<cmd>TmuxNavigateRight<cr>";
      }
      {
        key = "<leader>d";
        mode = "n";
        action = "<CMD>lua vim.diagnostic.open_float()<CR>";
        silent = true;
        desc = "Show diagnostics";
      }

      {
        key = "<C-h>";
        mode = "i";
        silent = true;
        action = "<Left>";
        noremap = true;
      }
      {
        key = "<C-j>";
        mode = "i";
        silent = true;
        action = "<Down>";
        noremap = true;
      }
      {
        key = "<C-k>";
        mode = "i";
        silent = true;
        action = "<Up>";
        noremap = true;
      }
      {
        key = "<C-l>";
        mode = "i";
        silent = true;
        action = "<Right>";
        noremap = true;
      }

      # Disable Arrow Keys in Normal Mode
      {
        key = "<Up>";
        mode = [
          "n"
          "i"
          "v"
        ];
        silent = true;
        action = "<Nop>";
        desc = "Disable Up Arrow";
      }
      {
        key = "<Down>";
        mode = [
          "n"
          "i"
          "v"
        ];
        silent = true;
        action = "<Nop>";
        desc = "Disable Down Arrow";
      }
      {
        key = "<Left>";
        mode = [
          "n"
          "i"
          "v"
        ];
        silent = true;
        action = "<Nop>";
        desc = "Disable Left Arrow";
      }
      {
        key = "<Right>";
        mode = [
          "n"
          "i"
          "v"
        ];
        silent = true;
        action = "<Nop>";
        desc = "Disable Right Arrow";
      }

      # UI
      {
        key = "<leader>uw";
        mode = "n";
        silent = true;
        action = "<cmd>set wrap!<cr>";
        desc = "Toggle word wrapping";
      }
      {
        key = "<leader>ul";
        mode = "n";
        silent = true;
        action = "<cmd>set linebreak!<cr>";
        desc = "Toggle linebreak";
      }
      {
        key = "<leader>us";
        mode = "n";
        silent = true;
        action = "<cmd>set spell!<cr>";
        desc = "Toggle spellLazyGitcheck";
      }
      {
        key = "<leader>uc";
        mode = "n";
        silent = true;
        action = "<cmd>set cursorline!<cr>";
        desc = "Toggle cursorline";
      }
      {
        key = "<leader>un";
        mode = "n";
        silent = true;
        action = "<cmd>set number!<cr>";
        desc = "Toggle line numbers";
      }
      {
        key = "<leader>ur";
        mode = "n";
        silent = true;
        action = "<cmd>set relativenumber!<cr>";
        desc = "Toggle relative line numbers";
      }
      {
        key = "<leader>ut";
        mode = "n";
        silent = true;
        action = "<cmd>set showtabline=2<cr>";
        desc = "Show tabline";
      }
      {
        key = "<leader>uT";
        mode = "n";
        silent = true;
        action = "<cmd>set showtabline=0<cr>";
        desc = "Hide tabline";
      }

      # Windows
      {
        key = "<leader>ws";
        mode = "n";
        silent = true;
        action = "<cmd>split<cr>";
        desc = "Split";
      }
      {
        key = "<leader>wv";
        mode = "n";
        silent = true;
        action = "<cmd>vsplit<cr>";
        desc = "VSplit";
      }
      {
        key = "<leader>wd";
        mode = "n";
        silent = true;
        action = "<cmd>close<cr>";
        desc = "Close";
      }
      {
        key = "<leader>rs";
        mode = "n";
        action = ":LspRestart<CR>";
        silent = true;
        desc = "Restart LSP";
      }
    ];
  };
}
