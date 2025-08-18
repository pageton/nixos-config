require("plugins")
require("lsp")

vim.cmd([[set mouse=]])
vim.o.number = true
vim.o.hlsearch = false
vim.o.relativenumber = true
vim.o.signcolumn = "yes"
vim.o.wrap = false
vim.o.tabstop = 2
vim.o.smartindent = true
vim.o.swapfile = false
vim.o.termguicolors = true
vim.o.cursorcolumn = false
vim.o.ignorecase = true
vim.o.clipboard = "unnamedplus"
vim.o.guifont = "FiraCode Nerd Font:h14"
vim.g.mapleader = " "
vim.o.winborder = "rounded"
vim.o.undofile = true
vim.o.timeout = true
vim.o.timeoutlen = 500
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
require("mason").setup()
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
			["<Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_next_item()
				elseif luasnip.expand_or_jumpable() then
					luasnip.expand_or_jump()
				else
					fallback()
				end
			end, { "i", "s" }),
			["<S-Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_prev_item()
				elseif luasnip.jumpable(-1) then
					luasnip.jump(-1)
				else
					fallback()
				end
			end, { "i", "s" }),
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

local function setup_none_ls()
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
	vim.keymap.set("n", "<leader>lf", function()
		vim.lsp.buf.format({ async = true })
	end, { desc = "Format with LSP" })
end

setup_none_ls()

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
