local util = require("lspconfig.util")
local lspconfig = require("lspconfig")
local cmp_nvim_lsp = require("cmp_nvim_lsp")

vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	underline = true,
	update_in_insert = false,
})

local capabilities = cmp_nvim_lsp.default_capabilities()

local function on_attach(_, bufnr)
	local opts = { buffer = bufnr, silent = true }
	vim.keymap.set(
		"n",
		"gR",
		"<cmd>Telescope lsp_references<CR>",
		vim.tbl_extend("force", opts, { desc = "Show LSP references" })
	)
	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
	vim.keymap.set(
		"n",
		"gd",
		"<cmd>Telescope lsp_definitions<CR>",
		vim.tbl_extend("force", opts, { desc = "Show LSP definitions" })
	)
	vim.keymap.set(
		"n",
		"gi",
		"<cmd>Telescope lsp_implementations<CR>",
		vim.tbl_extend("force", opts, { desc = "Show LSP implementations" })
	)
	vim.keymap.set(
		"n",
		"gt",
		"<cmd>Telescope lsp_type_definitions<CR>",
		vim.tbl_extend("force", opts, { desc = "Show LSP type definitions" })
	)
	vim.keymap.set(
		{ "n", "v" },
		"<leader>ca",
		vim.lsp.buf.code_action,
		vim.tbl_extend("force", opts, { desc = "See available code actions" })
	)
	vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Smart rename" }))
	vim.keymap.set(
		"n",
		"<leader>D",
		"<cmd>Telescope diagnostics bufnr=0<CR>",
		vim.tbl_extend("force", opts, { desc = "Show buffer diagnostics" })
	)
	vim.keymap.set(
		"n",
		"<leader>d",
		vim.diagnostic.open_float,
		vim.tbl_extend("force", opts, { desc = "Show line diagnostics" })
	)
	vim.keymap.set(
		"n",
		"K",
		vim.lsp.buf.hover,
		vim.tbl_extend("force", opts, { desc = "Show documentation for what is under cursor" })
	)
	vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>", vim.tbl_extend("force", opts, { desc = "Restart LSP" }))
	vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
end
local lsp_servers = {
	svelte = function()
		lspconfig.svelte.setup({
			capabilities = capabilities,
			on_attach = function(client)
				on_attach(client, 0)
				vim.api.nvim_create_autocmd("BufWritePost", {
					pattern = { "*.svelte", "*.js", "*.ts" },
					callback = function(ctx)
						client:notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
					end,
				})
			end,
		})
	end,
	lua_ls = function()
		lspconfig.lua_ls.setup({
			capabilities = capabilities,
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
					completion = {
						callSnippet = "Replace",
					},
				},
			},
			on_attach = on_attach,
		})
	end,
	gopls = function()
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
					analyses = {
						unusedparams = true,
						shadow = true,
					},
					staticcheck = true,
					completeUnimported = true,
					usePlaceholders = true,
					hoverKind = "Structured",
					linksInHover = true,
					experimentalPostfixCompletions = true,
				},
			},
		})

		vim.api.nvim_create_autocmd("BufWritePost", {
			pattern = "*.go",
			callback = function() end,
		})
	end,
	nil_ls = function()
		lspconfig.nil_ls.setup({
			capabilities = capabilities,
			filetypes = { "nix" },
			settings = {
				["nil"] = {
					formatting = {
						command = { "nixpkgs-fmt" },
					},
				},
			},
			on_attach = on_attach,
		})
	end,
}

for _, setup_func in pairs(lsp_servers) do
	if type(setup_func) == "function" then
		setup_func()
	end
end
