vim.cmd([[set mouse=]])
vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = "yes"
vim.o.wrap = false
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.swapfile = false
vim.opt.clipboard = "unnamedplus"
vim.g.mapleader = " "
vim.o.winborder = "rounded"
vim.o.cursorline = true
vim.o.cursorcolumn = false
vim.o.hlsearch = false
vim.o.undofile = true
vim.o.termguicolors = true
vim.o.timeoutlen = 500

vim.keymap.set("n", "<leader>o", ":update<CR> :source<CR>")
vim.keymap.set("n", "<leader>w", ":write<CR>")
vim.keymap.set("n", "<leader>wq", ":write<CR> :quit<CR>")
vim.keymap.set("n", "<leader>q", ":quit<CR>")
vim.keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
vim.keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

vim.keymap.set("i", "<C-h>", "<Left>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-l>", "<Right>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-j>", "<Down>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-k>", "<Up>", { noremap = true, silent = true })

vim.keymap.set({ "n", "v", "i" }, "<Left>", "<Nop>")
vim.keymap.set({ "n", "v", "i" }, "<Right>", "<Nop>")
vim.keymap.set({ "n", "v", "i" }, "<Up>", "<Nop>")
vim.keymap.set({ "n", "v", "i" }, "<Down>", "<Nop>")

vim.keymap.set("n", "<leader>tt", ":tabnew<CR>")
vim.keymap.set("n", "<leader>ww", ":tabclose<CR>")
vim.keymap.set("n", "<C-[>", ":tabprevious<CR>")
vim.keymap.set("n", "<C-]>", ":tabnext<CR>")
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })
vim.keymap.set("n", "<leader>cc", "<cmd>ClaudeCode<CR>", { desc = "Toggle Claude Code" })

vim.diagnostic.config({
	virtual_text = true,
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

vim.pack.add({
	{ src = "https://github.com/catppuccin/nvim" },
	{ src = "https://github.com/echasnovski/mini.pick" },
	{ src = "https://github.com/nvim-lualine/lualine.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "master" },
	{ src = "https://github.com/malbertzard/inline-fold.nvim" },
	{ src = "https://github.com/hrsh7th/nvim-cmp" },
	{ src = "https://github.com/hrsh7th/cmp-nvim-lsp" },
	{ src = "https://github.com/hrsh7th/cmp-buffer" },
	{ src = "https://github.com/hrsh7th/cmp-path" },
	{ src = "https://github.com/hrsh7th/cmp-cmdline" },
	{ src = "https://github.com/L3MON4D3/LuaSnip" },
	{ src = "https://github.com/saadparwaiz1/cmp_luasnip" },

	{ src = "https://github.com/nvim-neo-tree/neo-tree.nvim" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/MunifTanjim/nui.nvim" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },

	{ src = "https://github.com/christoomey/vim-tmux-navigator" },

	{ src = "https://github.com/nvim-telescope/telescope.nvim" },
	{ src = "https://github.com/nvim-telescope/telescope-ui-select.nvim" },

	{ src = "https://github.com/windwp/nvim-autopairs" },

	{ src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
	{ src = "https://github.com/TheGLander/indent-rainbowline.nvim" },

	{ src = "https://github.com/numToStr/Comment.nvim" },
	{ src = "https://github.com/folke/todo-comments.nvim" },

	{ src = "https://github.com/rafamadriz/friendly-snippets" },
	{ src = "https://github.com/onsails/lspkind.nvim" },

	{ src = "https://github.com/kylechui/nvim-surround" },

	{ src = "https://github.com/stevearc/dressing.nvim" },

	{ src = "https://github.com/akinsho/bufferline.nvim" },

	{ src = "https://github.com/windwp/nvim-ts-autotag" },

	{ src = "https://github.com/Exafunction/windsurf.nvim" },

	{ src = "https://github.com/lewis6991/gitsigns.nvim" },

	{ src = "https://github.com/nvimtools/none-ls.nvim" },

	{ src = "https://github.com/folke/which-key.nvim" },

	{ src = "https://github.com/mfussenegger/nvim-lint" },

	{ src = "https://github.com/olexsmir/gopher.nvim" },

	{ src = "https://github.com/stevearc/conform.nvim" },

	{ src = "https://github.com/wakatime/vim-wakatime" },

	{ src = "https://github.com/greggh/claude-code.nvim" },

	{ src = "https://github.com/olrtg/nvim-emmet" },

	{ src = "https://github.com/folke/noice.nvim" },
	{ src = "https://github.com/rcarriga/nvim-notify" },

	{ src = "https://github.com/TabbyML/vim-tabby" },
	{ src = "https://github.com/nzlov/cmp-tabby" },
})

require("mini.pick").setup()

require("lualine").setup({
	options = { theme = "catppuccin-mocha" },
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

vim.g.tabby_agent_start_command = { "npx", "tabby-agent", "--stdio" }
vim.g.tabby_inline_completion_trigger = "auto"

local last_press = 0
vim.keymap.set("n", "<CR>", function()
	local current_time = vim.fn.reltimefloat(vim.fn.reltime())
	if current_time - last_press < 0.5 then
		require("which-key").show()
	end
	last_press = current_time
end)

require("noice").setup({
	lsp = {
		-- override markdown rendering so that **cmp** and other plugins use **Treesitter**
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
		},
	},
	-- you can enable a preset for easier configuration
	presets = {
		bottom_search = false, -- use a classic bottom cmdline for search
		command_palette = true, -- position the cmdline and popupmenu together
		long_message_to_split = true, -- long messages will be sent to a split
		inc_rename = false, -- enables an input dialog for inc-rename.nvim
		lsp_doc_border = false, -- add a border to hover docs and signature help
	},
})

require("inline-fold").setup({
	defaultPlaceholder = "…",
	queries = {
		html = {
			{ pattern = 'class="([^"]*)"' },
			{ pattern = 'href="(.-)"' },
			{ pattern = 'src="(.-)"' },
		},
		javascriptreact = {
			{ pattern = 'className="([^"]*)"' },
			{ pattern = 'href="(.-)"' },
			{ pattern = 'src="(.-)"' },
		},
		typescriptreact = {
			{ pattern = 'className="([^"]*)"' },
			{ pattern = 'href="(.-)"' },
			{ pattern = 'src="(.-)"' },
		},
	},
})

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	pattern = { "*.html", "*.tsx", "*.jsx" },
	callback = function(_)
		if not require("inline-fold.module").isHidden then
			vim.cmd("InlineFoldToggle")
		end
	end,
})

require("dressing").setup({
	input = {
		enabled = true,
		default_prompt = " ",
		borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
	},
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
vim.cmd.colorscheme("catppuccin")

require("bufferline").setup({
	options = {
		mode = "tabs",
		separator_style = "slant",
		always_show_bufferline = true,
		show_buffer_icons = true,
		show_buffer_close_icons = true,
	},
})

require("claude-code").setup({
	window = {
		position = "float",
		float = {
			width = "90%", -- Take up 90% of the editor width
			height = "90%", -- Take up 90% of the editor height
			row = "center", -- Center vertically
			col = "center", -- Center horizontally
			relative = "editor",
			border = "double", -- Use double border style
		},
	},
})

require("neo-tree").setup({
	filesystem = {
		filtered_items = {
			visible = true,
			hide_dotfiles = false,
		},
		follow_current_file = {
			enabled = true,
			leave_dirs_open = false,
		},
		hijack_netrw_behavior = "open_default",
		hide_dotfiles = false,
	},
	window = {
		position = "left",
		width = 35,
	},
})

require("gitsigns").setup({
	on_attach = function(bufnr)
		local gs = package.loaded.gitsigns
		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
		end

		map("n", "]h", gs.next_hunk, "Next Hunk")
		map("n", "[h", gs.prev_hunk, "Prev Hunk")

		map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
		map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
		map("v", "<leader>hs", function()
			gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, "Stage hunk")
		map("v", "<leader>hr", function()
			gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, "Reset hunk")

		map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
		map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")

		map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")

		map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
		map("n", "<leader>hb", function()
			gs.blame_line({ full = true })
		end, "Blame line")
		map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle line blame")

		map("n", "<leader>hd", gs.diffthis, "Diff this")
		map("n", "<leader>hD", function()
			gs.diffthis("~")
		end, "Diff this ~")

		map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Gitsigns select hunk")
	end,
})

require("nvim-surround").setup({
	keymaps = {
		normal = "sa",
		normal_cur = "saa",
		normal_line = "sA",
		visual = "S",
		visual_line = "gS",
		delete = "dS",
		change = "cS",
	},
})

require("ibl").setup(
	require("indent-rainbowline").make_opts({}, {
		color_transparency = 0.15,
		colors = { 0xffff40, 0x79ff79, 0xff79ff, 0x4fecec },
	}),
	{
		indent = { char = "│" },
		whitespace = {
			remove_blankline_trail = false,
		},
		scope = {
			enabled = true,
			show_start = true,
			show_end = true,
			highlight = { "Function", "Label" },
		},
	}
)

require("gopher").setup()

require("nvim-treesitter.install").update({ with_sync = true })

require("nvim-autopairs").setup({ check_ts = true })

require("telescope").setup({
	extensions = {
		["ui-select"] = {
			require("telescope.themes").get_dropdown({}),
		},
	},
})
require("telescope").load_extension("ui-select")

require("todo-comments").setup()
require("Comment").setup()

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

vim.keymap.set("n", "<C-h>", "<CMD>TmuxNavigateLeft<CR>", { desc = "Navigate left" })
vim.keymap.set("n", "<C-j>", "<CMD>TmuxNavigateDown<CR>", { desc = "Navigate down" })
vim.keymap.set("n", "<C-k>", "<CMD>TmuxNavigateUp<CR>", { desc = "Navigate up" })
vim.keymap.set("n", "<C-l>", "<CMD>TmuxNavigateRight<CR>", { desc = "Navigate right" })
vim.keymap.set("n", "<C-\\>", "<CMD>TmuxNavigatePrevious<CR>", { desc = "Navigate previous" })

vim.keymap.set("n", "<leader>dg", "<cmd>GoTagAdd json<CR>", { desc = "Add json struct tag" })
vim.keymap.set("n", "<leader>dt", "<cmd>GoTagAdd toml<CR>", { desc = "Add toml struct tag" })
vim.keymap.set("n", "<leader>dy", "<cmd>GoTagAdd yaml<CR>", { desc = "Add yaml struct tag" })
vim.keymap.set("n", "<leader>ds", "<cmd>GoTagAdd sql<CR>", { desc = "Add sql struct tag" })

vim.keymap.set({ "n", "v" }, "<leader>xe", require("nvim-emmet").wrap_with_abbreviation)

vim.keymap.set({ "n", "i" }, "<C-_>", function()
	require("Comment.api").toggle.linewise.current()
end, { noremap = true, silent = true })

vim.keymap.set("v", "<C-_>", function()
	require("Comment.api").toggle.linewise(vim.fn.visualmode())
end, { noremap = true, silent = true })

vim.keymap.set("n", "<leader>f", ":Pick files<CR>")
vim.keymap.set("n", "<leader>h", ":Pick help<CR>")

-- vim.lsp.enable({ "lua_ls", "ts_ls", "nil" })
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

vim.keymap.set("n", "<C-n>", ":Neotree toggle<CR>", { desc = "Toggle Neo-Tree" })

local telescope_builtin = require("telescope.builtin")

vim.keymap.set("n", "<C-p>", telescope_builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<C-f>", telescope_builtin.live_grep, { desc = "Find text" })
vim.keymap.set("n", "<leader>:", telescope_builtin.command_history, { desc = "Command history" })
vim.keymap.set("n", "<leader><leader>", telescope_builtin.oldfiles, { desc = "Recently opened files" })

vim.keymap.set("n", "<leader>td", ":TodoTelescope<CR>", { desc = "Show TODO comments" })

vim.cmd(":hi statusline guibg=NONE")

require("nvim-ts-autotag").setup({
	opts = {
		enable_close = true,
		enable_rename = true,
		enable_close_on_slash = false,
	},
})

require("nvim-treesitter.configs").setup({
	highlight = {
		enable = true,
	},
	indent = {
		enable = true,
	},
	autotag = {
		enable = false,
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

local cmp = require("cmp")
local luasnip = require("luasnip")
local lspkind = require("lspkind")

lspkind.init({
	symbol_map = {
		Supermaven = "",
	},
})

vim.api.nvim_set_hl(0, "CmpItemKindSupermaven", { fg = "#6CC644" })

require("luasnip.loaders.from_vscode").lazy_load()

local tabby = require("cmp_tabby.config")

tabby:setup({
	host = "localhost",
	port = 9090,
	max_lines = 1000,
})

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
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = false }),
	}),
	sources = cmp.config.sources({
		{ name = "tabby" },
		{ name = "cmp_tabby" },
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
		{ name = "buffer" },
		{ name = "path" },
	}),
	formatting = {
		format = function(entry, vim_item)
			if entry.source.name == "cmp_tabby" then
				vim_item.kind = "🤖"
				vim_item.menu = "[Tabby]"
			elseif entry.source.name == "luasnip" then
				vim_item.kind = ""
				vim_item.menu = "[Snippet]"
			elseif entry.source.name == "nvim_lsp" then
				vim_item.kind = "λ"
				vim_item.menu = "[LSP]"
			else
				vim_item.menu = "[" .. entry.source.name .. "]"
			end

			return vim_item
		end,
	},
	completion = {
		completeopt = "menu,menuone,preview,noselect",
	},

	window = {
		completion = cmp.config.window.bordered({
			border = "rounded",
			winhighlight = "NormalFloat:CmpPmenu,CursorLine:CmpPmenuSel,Search:None",
			side_padding = 1,
		}),
		documentation = cmp.config.window.bordered({
			border = "rounded",
			winhighlight = "NormalFloat:CmpDoc,FloatBorder:CmpDocBorder",
		}),
	},
})

vim.api.nvim_set_hl(0, "CmpPmenuSel", { bg = "#373c48", fg = "#ffffff" })
-- Command-line setup
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

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*.go",
	callback = function()
		local client = vim.lsp.get_clients({ name = "gopls" })[1]
		if not client then
			return
		end

		local params = vim.lsp.util.make_range_params(nil, client.offset_encoding)
		params.context = { only = { "source.organizeImports" } }

		local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
		if not result then
			return
		end

		for cid, res in pairs(result) do
			for _, r in pairs(res.result or {}) do
				if r.edit then
					local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
					vim.lsp.util.apply_workspace_edit(r.edit, enc)
				end
			end
		end

		vim.lsp.buf.format({ async = false })
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and not client.offset_encoding then
			client.offset_encoding = "utf-16"
		end
	end,
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

vim.lsp.config["luals"] = {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	capabilities = capabilities,
}

vim.lsp.config["gopls"] = {
	capabilities = capabilities,
	settings = {
		gopls = {
			hints = {
				assignVariableTypes = true,
				compositeLiteralFields = true,
				compositeLiteralTypes = true,
				constantValues = true,
				functionTypeParameters = true,
				parameterNames = true,
				rangeVariableTypes = true,
			},
			analyses = {
				unusedparams = true,
				shadow = true,
			},
			staticcheck = true,
			gofumpt = true,
			completeUnimported = true,
			usePlaceholders = true,
			hoverKind = "FullDocumentation",
			linksInHover = true,
			experimentalPostfixCompletions = true,
		},
	},
}

vim.lsp.config["rust-analyzer"] = {
	cmd = { "rust-analyzer" },
	filetypes = { "rust" },
	root_markers = { "Cargo.toml", ".git" },
	capabilities = capabilities,
	settings = {
		["rust-analyzer"] = {
			cargo = { allFeatures = true },
			checkOnSave = true,
			diagnostics = { enable = true },
			inlayHints = {
				enable = true,
				typeHints = true,
				parameterHints = true,
				chainingHints = true,
			},
			assist = {
				importGranularity = "module",
				importPrefix = "by_self",
			},
			lens = {
				enable = true,
			},
			completion = {},
			procMacro = {
				ignored = {
					leptos_macro = {
						"component",
						"server",
					},
				},
			},
			rustfmt = {
				overrideCommand = { "rustfmt", "--edition", "2024" },
				config = "~/.config/rustfmt/rustfmt.toml",
			},
		},
	},
}

vim.lsp.config["tsls"] = {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = {
		"javascript",
		"javascriptreact",
		"javascript.jsx",
		"typescript",
		"typescriptreact",
		"typescript.tsx",
		"vue",
	},
	preferences = {
		includeInlayParameterNameHints = "all",
		includeInlayPropertyDeclarationTypeHints = true,
		includeInlayFunctionLikeReturnTypeHints = true,
		includeInlayVariableTypeHints = true,
		includeInlayEnumMemberValueHints = true,
	},
	codeActionsOnSave = {
		["source.organizeImports"] = true,
	},
	suggestions = {
		completeFunctionCalls = true,
		classMemberSnippets = true,
		objectLiteralMethodSnippets = true,
		autoImports = true,
	},
	capabilities = capabilities,
}

vim.lsp.config["nil_ls"] = {
	cmd = { "nil" },
	filetypes = { "nix" },
	capabilities = capabilities,
}

vim.lsp.config["html"] = {
	filetypes = { "html" },
	capabilities = capabilities,
}

vim.lsp.config["cssls"] = {
	filetypes = { "css" },
	capabilities = capabilities,
}

vim.lsp.config["tailwindcss"] = {
	cmd = { "tailwindcss-language-server", "--stdio" },
	capabilities = capabilities,
	filetypes = {
		"html",
		"javascript",
		"typescript",
		"javascriptreact",
		"typescriptreact",
		"vue",
		"css",
		"javascript.jsx",
		"typescript.tsx",
	},
}

vim.lsp.config["emmet_language_server"] = {
	filetypes = {
		"css",
		"eruby",
		"html",
		"javascript",
		"typescript",
		"javascriptreact",
		"less",
		"sass",
		"scss",
		"pug",
		"typescriptreact",
	},
	init_options = {
		---@type table<string, string>
		includeLanguages = {},
		--- @type string[]
		excludeLanguages = {},
		--- @type string[]
		extensionsPath = {},
		--- @type table<string, any>
		preferences = {},
		--- @type boolean Defaults to `true`
		showAbbreviationSuggestions = true,
		--- @type "always" | "never" Defaults to `"always"`
		showExpandedAbbreviation = "always",
		--- @type boolean Defaults to `false`
		showSuggestionsAsSnippets = false,
		--- @type table<string, any>
		syntaxProfiles = {},
		--- @type table<string, string>
		variables = {},
	},
}

vim.lsp.enable({
	"luals",
	"tsls",
	"gopls",
	"nil_ls",
	"html",
	"cssls",
	"tailwindcss",
	"emmet_language_server",
	"rust-analyzer",
})

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
		graphql = { "biome" },
		liquid = { "prettier" },
		lua = { "stylua" },
		python = { "ruff" },
		go = { "gofumpt", "goimports_reviser", "golines" },
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
