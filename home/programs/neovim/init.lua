-- Vim Packages
vim.pack.add({
        { src = "https://github.com/catppuccin/nvim" },
        { src = "https://github.com/echasnovski/mini.pick" },
        { src = "https://github.com/neovim/nvim-lspconfig" },
        { src = "https://github.com/chomosuke/typst-preview.nvim" },
        { src = "https://github.com/wakatime/vim-wakatime" },
        { src = "https://github.com/numToStr/Comment.nvim" },
        { src = "https://github.com/folke/todo-comments.nvim" },
        { src = "https://github.com/folke/which-key.nvim" },
        { src = "https://github.com/nvim-lua/plenary.nvim" },
        { src = "https://github.com/nvim-treesitter/nvim-treesitter",        version = "master" },
        { src = "https://github.com/supermaven-inc/supermaven-nvim" },
        { src = "https://github.com/nvim-neo-tree/neo-tree.nvim" },
        { src = "https://github.com/nvim-tree/nvim-web-devicons" },
        { src = "https://github.com/MunifTanjim/nui.nvim" },
        { src = "https://github.com/christoomey/vim-tmux-navigator" },
        { src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
        { src = "https://github.com/nvim-lualine/lualine.nvim" },
        { src = "https://github.com/nvim-telescope/telescope.nvim" },
        { src = "https://github.com/nvim-telescope/telescope-ui-select.nvim" },
        { src = "https://github.com/hrsh7th/nvim-cmp" },
        { src = "https://github.com/hrsh7th/cmp-nvim-lsp" },
        { src = "https://github.com/hrsh7th/cmp-buffer" },
        { src = "https://github.com/hrsh7th/cmp-path" },
        { src = "https://github.com/hrsh7th/cmp-cmdline" },
        {
                src = "https://github.com/L3MON4D3/LuaSnip",
                version = "v2.*",
                build = "make install_jsregex",
        },
        { src = "https://github.com/saadparwaiz1/cmp_luasnip" },
        { src = "https://github.com/rafamadriz/friendly-snippets" },
        { src = "https://github.com/onsails/lspkind.nvim" },
        { src = "https://github.com/nvimtools/none-ls.nvim" },
        { src = "https://github.com/mason-org/mason.nvim" },
        { src = "https://github.com/kylechui/nvim-surround" },
        { src = "https://github.com/stevearc/conform.nvim" },
        { src = "https://github.com/windwp/nvim-autopairs" },
        { src = "https://github.com/akinsho/bufferline.nvim" },
        { src = "https://github.com/mfussenegger/nvim-lint" },
        { src = "https://github.com/olexsmir/gopher.nvim" },
        { src = "https://github.com/antosha417/nvim-lsp-file-operations" },
        { src = "https://github.com/stevearc/dressing.nvim" },
        { src = "https://github.com/windwp/nvim-ts-autotag" },
        { src = "https://github.com/folke/neodev.nvim",                        opts = {} },
        { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
        { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
})

vim.cmd([[set mouse=]])
vim.o.number = true
vim.o.hlsearch = false
vim.o.relativenumber = true
vim.o.signcolumn = "yes"
vim.o.wrap = false
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.swapfile = false
vim.o.termguicolors = true
vim.o.cursorcolumn = false
vim.o.cursorline = true
vim.o.ignorecase = true
vim.o.clipboard = "unnamedplus"
vim.o.guifont = "FiraCode Nerd Font:h14"
vim.g.mapleader = " "
vim.o.winborder = "rounded"
vim.o.undofile = true
vim.o.timeout = true
vim.o.timeoutlen = 500
vim.o.expandtab = true
vim.lsp.enable("lua_ls", "gopls")
-- vim.cmd("colorscheme catppuccin-mocha")

-- Bindings
local map = vim.keymap.set
map("n", "<leader>o", ":update<CR> :source<CR>")
map("n", "<leader>w", ":write<CR>")
map("n", "<leader>wq", ":write<CR> :quit<CR>")
map("n", "<leader>q", ":quit<CR>")
map("n", "<leader>lf", vim.lsp.buf.format)
map("n", "<leader>f", ":Pick files<CR>")
map("n", "<leader>h", ":Pick help<CR>")
map("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
map("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })
map("n", "<leader>rr", ":restart<CR>", { desc = "Restart nvim" })
map({ "n", "i" }, "<C-_>", function()
        require("Comment.api").toggle.linewise.current()
end, { noremap = true, silent = true })
map("n", "<leader>tt", ":tabnew<CR>")
map("n", "<leader>ww", ":tabclose<CR>")
map("n", "<C-]>", ":tabprevious<CR>")
map("n", "<C-[>", ":tabnext<CR>")
map("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
map("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
map("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })
map("v", "<C-_>", function()
        require("Comment.api").toggle.linewise(vim.fn.visualmode())
end, { noremap = true, silent = true })
map("i", "<C-h>", "<Left>", { noremap = true, silent = true })
map("i", "<C-l>", "<Right>", { noremap = true, silent = true })
map("i", "<C-j>", "<Down>", { noremap = true, silent = true })
map("i", "<C-k>", "<Up>", { noremap = true, silent = true })

-- Disable arrow keys in normal, insert and visual modes
for _, mode in ipairs({ "n", "i", "v" }) do
        map(mode, "<Left>", "<Nop>")
        map(mode, "<Right>", "<Nop>")
        map(mode, "<Up>", "<Nop>")
        map(mode, "<Down>", "<Nop>")
end

map("n", "<C-n>", ":Neotree toggle<CR>", { desc = "Toggle Neo-tree" })

-- tmux navigation
map("n", "<C-h>", "<CMD>TmuxNavigateLeft<CR>", { desc = "Navigate left" })
map("n", "<C-j>", "<CMD>TmuxNavigateDown<CR>", { desc = "Navigate down" })
map("n", "<C-k>", "<CMD>TmuxNavigateUp<CR>", { desc = "Navigate up" })
map("n", "<C-l>", "<CMD>TmuxNavigateRight<CR>", { desc = "Navigate right" })
map("n", "<C-\\>", "<CMD>TmuxNavigatePrevious<CR>", { desc = "Navigate previous" })

local telescope_builtin = require("telescope.builtin")

map("n", "<C-p>", telescope_builtin.find_files, { desc = "Find files" })
map("n", "<C-f>", telescope_builtin.live_grep, { desc = "Find text" })
map("n", "<leader>:", telescope_builtin.command_history, { desc = "Command history" })
map("n", "<leader><leader>", telescope_builtin.oldfiles, { desc = "Recently opened files" })

map("n", "<leader>ts", function()
        telescope_builtin.find_files({
                prompt_title = "Tmux Sessions",
                cwd = vim.fn.expand("~/.tmux/resurrect/"),
                attach_mappings = function(prompt_bufnr, telescope_map)
                        local actions = require("telescope.actions")
                        local action_state = require("telescope.actions.state")

                        telescope_map("i", "<CR>", function()
                                local entry = action_state.get_selected_entry().value
                                local path = vim.fn.expand("~/.tmux/resurrect/") .. "/" .. entry
                                vim.fn.system({ "cp", path, vim.fn.expand("~/.tmux/resurrect/last") })
                                print("Restored tmux session: " .. entry)
                                actions.close(prompt_bufnr)
                        end)

                        telescope_map("i", "<S-CR>", function()
                                local entry = action_state.get_selected_entry().value
                                vim.fn.setreg("+", entry)
                                print("Copied session file to clipboard: " .. entry)
                                actions.close(prompt_bufnr)
                        end)

                        return true
                end,
        })
end, { desc = "Browse & Restore Tmux Sessions" })

local last_press = 0
map("n", "<CR>", function()
        local current_time = vim.fn.reltimefloat(vim.fn.reltime())
        if current_time - last_press < 0.5 then
                require("which-key").show()
        end
        last_press = current_time
end)

map("n", "<leader>dg", "<cmd> GoTagAdd json <CR>", { desc = "Add json struct tag" })
map("n", "<leader>dt", "<cmd> GoTagAdd toml <CR>", { desc = "Add toml struct tag" })
map("n", "<leader>dy", "<cmd> GoTagAdd yaml <CR>", { desc = "Add yaml struct tag" })
map("n", "<leader>ds", "<cmd> GoTagAdd sql <CR>", { desc = "Add sql struct tag" })

-- Additional recommended keymaps
map("n", "<leader>nt", ":Neotree toggle<CR>", { desc = "Toggle Neo-tree file explorer" })
map("n", "<leader>tt", ":TodoTelescope<CR>", { desc = "Show TODO comments" })
map("n", "<leader>rl", ":source $MYVIMRC<CR>", { desc = "Reload config" })

if not vim.g.supermaven_initialized then
        require("supermaven-nvim").setup({
                keymaps = {
                        accept_suggestion = "<Tab>",
                        clear_suggestion = "<C-]>",
                        accept_word = "<D-j>",
                },
                ignore_filetypes = { cpp = true },
                color = {
                        suggestion_color = "#ffffff",
                        cterm = 244,
                },
                log_level = "info",
                disable_inline_completion = false,
                disable_keymaps = false,
                condition = function()
                        return false
                end,
        })
        vim.g.supermaven_initialized = true
end

require("nvim-treesitter.configs").setup({
        highlight = {
                enable = true,
        },
        indent = {
                enable = true,
        },
        autotag = {
                enable = true,
        },
        incremental_selection = {
                enable = true,
                keymaps = {
                        init_selection = "<leader>gnn",
                        node_incremental = "<leader>grn",
                        scope_incremental = false,
                        node_decremental = "<bs>",
                },
        },
        ensure_installed = {
                "lua",
                "python",
                "javascript",
                "typescript",
                "go",
                "html",
                "css",
                "json",
                "bash",
                "markdown",
                "rust",
                "zig",
                "c",
                "toml",
                "dockerfile",
                "yaml",
                "nix",
        },
        auto_install = true,
        sync_install = true,
})

require("catppuccin").setup({
        flavour = "mocha",
        integrations = {
                cmp = true,
                gitsigns = true,
                nvimtree = true,
                treesitter = true,
                telescope = true,
        },
})
vim.cmd("colorscheme catppuccin")
require("mini.pick").setup()
require("todo-comments").setup()
require("Comment").setup()
require("dressing").setup({
        input = {
                enabled = true,
                default_prompt = " ",
                borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        },
})
require("nvim-autopairs").setup({ check_ts = true })
require("bufferline").setup({
        options = {
                mode = "tabs",
                separator_style = "slant",
                always_show_bufferline = true,
                show_buffer_icons = true,
                show_buffer_close_icons = true,
        },
})
require("gopher").setup({})
require("neo-tree").setup({
        filesystem = {
                filtered_items = {
                        visible = true,
                        hide_dotfiles = false,
                },
        },
})
require("ibl").setup({
        indent = { char = "┊" },
        whitespace = {
                remove_blankline_trail = false,
        },
        scope = {
                enabled = true,
                show_start = true,
                show_end = true,
                highlight = { "Function", "Label" },
        },
})
require("which-key").setup({
        plugins = {
                marks = true,
                registers = true,
        },
        replace = {
                ["<leader>"] = "SPC",
        },
})
require("lualine").setup({
        options = {
                theme = "catppuccin-mocha",
        },
})
require("telescope").setup({
        extensions = {
                ["ui-select"] = {
                        require("telescope.themes").get_dropdown({}),
                },
        },
})
require("telescope").load_extension("ui-select")

local ok_cmp, cmp = pcall(require, "cmp")
local ok_luasnip, luasnip = pcall(require, "luasnip")
local ok_lspkind, lspkind = pcall(require, "lspkind")

if ok_cmp and ok_luasnip and ok_lspkind then
        local symbol_map = { Supermaven = "" }
        lspkind.init({ symbol_map = symbol_map })
        vim.api.nvim_set_hl(0, "CmpItemKindSupermaven", { fg = "#6CC644" })
        luasnip.config.set_config({ enable_autosnippets = true })
        cmp.setup({
                snippet = {
                        expand = function(args)
                                luasnip.lsp_expand(args.body)
                        end,
                },
                mapping = cmp.mapping.preset.insert({
                        ["<C-k>"] = cmp.mapping.select_prev_item(),
                        ["<C-j>"] = cmp.mapping.select_next_item(),
                        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                        ["<C-f>"] = cmp.mapping.scroll_docs(4),
                        ["<C-D>"] = cmp.mapping.complete(),
                        ["<C-e>"] = cmp.mapping.abort(),
                        ["<CR>"] = cmp.mapping.confirm({ select = false }),
                }),
                sources = cmp.config.sources({
                        { name = "nvim_lsp" },
                        { name = "luasnip" },
                        { name = "buffer" },
                        { name = "path" },
                        { name = "supermaven" },
                }),
                formatting = {
                        format = lspkind.cmp_format({
                                mode = "symbol",
                                maxwidth = 50,
                                symbol_map = symbol_map,
                                ellipsis_char = "...",
                        }),
                },
                window = {
                        completion = cmp.config.window.bordered(),
                        documentation = cmp.config.window.bordered(),
                },
                completion = {
                        completeopt = "menu,menuone,preview,noselect",
                },
        })
        cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                        { name = "cmdline" },
                        { name = "buffer" },
                }),
        })
        cmp.setup.cmdline("/", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                        { name = "buffer" },
                },
        })
        cmp.setup.cmdline("!", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                        { name = "path" },
                },
        })
end

local conform = require("conform")
conform.setup({
        formatters_by_ft = {
                javascript = { "biome" },
                typescript = { "biome" },
                javascriptreact = { "biome" },
                typescriptreact = { "biome" },
                svelte = { "biome" },
                css = { "biome" },
                html = { "biome" },
                json = { "biome" },
                yaml = { "biome" },
                markdown = { "biome" },
                liquid = { "prettier" },
                lua = { "stylua" },
                python = { "ruff" },
        },
        format_on_save = {
                lsp_fallback = true,
                async = false,
                timeout_ms = 1000,
        },
})

vim.keymap.set({ "n", "v" }, "<leader>mp", function()
        conform.format({
                lsp_fallback = true,
                async = false,
                timeout_ms = 1000,
        })
end, { desc = "Format file or range (in visual mode)" })

local lint = require("lint")
lint.linters_by_ft = {
        javascript = { "biomejs" },
        typescript = { "biomejs" },
        javascriptreact = { "biomejs" },
        typescriptreact = { "biomejs" },
        svelte = { "biomejs" },
        python = { "ruff" },
}

local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
                lint.try_lint()
        end,
})

vim.keymap.set("n", "<leader>l", function()
        lint.try_lint()
end, { desc = "Trigger linting for current file" })

local null_ls = require("null-ls")
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

null_ls.setup({
        sources = {
                null_ls.builtins.formatting.stylua,
                null_ls.builtins.formatting.biome,
                null_ls.builtins.formatting.gofumpt,
                null_ls.builtins.formatting.goimports_reviser,
                null_ls.builtins.formatting.golines.with({
                        extra_args = { "--max-len=120", "--shorten-comments" },
                }),
                null_ls.builtins.formatting.nixpkgs_fmt,
                -- null_ls.builtins.formatting.gofmt,
        },
        on_attach = function(client, bufnr)
                if client:supports_method("textDocument/formatting") then
                        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
                        vim.api.nvim_create_autocmd("BufWritePre", {
                                group = augroup,
                                buffer = bufnr,
                                callback = function()
                                        vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 2000 })
                                end,
                        })
                end
        end,
})

require("mason").setup({
        ui = {
                icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗",
                },
        },
})

local cmp_nvim_lsp = require("cmp_nvim_lsp")
local capabilities = cmp_nvim_lsp.default_capabilities()
local lspconfig = require("lspconfig")
local util = require("lspconfig.util")
require("mason-lspconfig").setup({
        automatic_installation = true,
        ensure_installed = {
                "lua_ls",
                "gopls",
                "nil_ls",
                "ts_ls",
                "biome",
                "svelte",
                "tailwindcss",
                "html",
        },
        handlers = {
                function(server_name)
                        lspconfig[server_name].setup({
                                capabilities = capabilities,
                        })
                end,
                ["lua_ls"] = function()
                        lspconfig.lua_ls.setup({
                                capabilities = capabilities,
                                settings = {
                                        Lua = {
                                                diagnostics = { globals = { "vim" } },
                                                completion = { callSnippet = "Replace" },
                                        },
                                },
                        })
                end,
                ["gopls"] = function()
                        lspconfig.gopls.setup({
                                cmd = { "gopls" },
                                filetypes = { "go", "gomod", "gowork", "gotmpl" },
                                root_dir = util.root_pattern("go.work", "go.mod", ".git"),
                                capabilities = capabilities,
                                init_options = {
                                        hints = {
                                                assignVariableTypes = true,
                                                compositeLiteralFields = true,
                                                compositeLiteralTypes = true,
                                                constantValues = true,
                                                functionTypeParameters = true,
                                                parameterNames = true,
                                                rangeVariableTypes = true,
                                        },
                                },
                                settings = {
                                        gopls = {
                                                formatting = true,
                                                analyses = { unusedparams = true, shadow = true },
                                                staticcheck = true,
                                                completeUnimported = true,
                                                usePlaceholders = true,
                                                hoverKind = "Structured",
                                                linksInHover = true,
                                                experimentalPostfixCompletions = true,
                                        },
                                },
                        })
                end,
                ["nil_ls"] = function()
                        lspconfig.nil_ls.setup({
                                capabilities = capabilities,
                                filetypes = { "nix" },
                                settings = {
                                        ["nil"] = {
                                                formatting = { command = { "nixpkgs-fmt" } },
                                        },
                                },
                        })
                end,
                ["svelte"] = function()
                        lspconfig.svelte.setup({
                                capabilities = capabilities,
                                on_attach = function(client, _)
                                        vim.api.nvim_create_autocmd("BufWritePost", {
                                                pattern = { "*.svelte", "*.js", "*.ts" },
                                                callback = function(ctx)
                                                        client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
                                                end,
                                        })
                                end,
                        })
                end,
                ["graphql"] = function()
                        lspconfig.graphql.setup({
                                capabilities = capabilities,
                                filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
                        })
                end,
        },
})

require("neodev").setup({})

vim.diagnostic.config({
        virtual_text = true,
        -- signs = true,
        underline = true,
        update_in_insert = false,
        signs = {
                text = {
                        [vim.diagnostic.severity.ERROR] = " ",
                        [vim.diagnostic.severity.WARN] = " ",
                        [vim.diagnostic.severity.HINT] = " ",
                        [vim.diagnostic.severity.INFO] = " ",
                },
        },
})

vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
                local opts = { buffer = ev.buf, silent = true }
                opts.desc = "Show LSP references"
                vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)
                opts.desc = "Go to declaration"
                vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
                opts.desc = "Show LSP definitions"
                vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
                opts.desc = "Show LSP implementations"
                vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
                opts.desc = "Show LSP type definitions"
                vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)
                opts.desc = "See available code actions"
                vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
                opts.desc = "Smart rename"
                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
                opts.desc = "Show buffer diagnostics"
                vim.keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)
                opts.desc = "Show line diagnostics"
                vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
                opts.desc = "Show documentation for what is under cursor"
                vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                opts.desc = "Restart LSP"
                vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
                opts.desc = "Go to Definition"
                vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                opts.desc = "Hover"
                vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                opts.desc = "References"
                vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, opts)
                opts.desc = "Code Action"
                vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        end,
})
