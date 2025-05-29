return {
	{ "neovim/nvim-lspconfig" },
	{ "hrsh7th/nvim-cmp" },
	{ "L3MON4D3/LuaSnip" },
	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v3.x",
		config = function()
			-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
			require("lspconfig").lua_ls.setup({})
			require("lspconfig").nil_ls.setup({})
			require("lspconfig").nixd.setup({
				cmd = { "nixd" },
				settings = {
					nixd = {
						nixpkgs = {
							expr = "import <nixpkgs> { }",
						},
						options = {
							nixos = {
								expr = '(builtins.getFlake "/home/wout/.nix").nixosConfigurations.framework.options',
							},
						},
					},
				},
			})
			require("lspconfig").ts_ls.setup({})
			require("lspconfig").terraformls.setup({})
			require("lspconfig").rust_analyzer.setup({})
			require("lspconfig").gopls.setup({})
			require("lspconfig").astro.setup({})
			require("lspconfig").ruby_lsp.setup({})
			require("lspconfig").sqls.setup({})
			require("lspconfig").htmx.setup({})
			require("lspconfig").html.setup({
				filetypes = { "html", "handlebars", "html.handlebars", "html.hbs" },
			})
			require("lspconfig").omnisharp.setup({
				cmd = {
					"OmniSharp",
					"--languageserver",
					"--hostPID",
					tostring(vim.fn.getpid()),
				},
				filetypes = { "cs", "vb" },
				root_markers = { ".sln", ".csproj", "omnisharp.json", "function.json" },
				settings = {
					FormattingOptions = {
						EnableEditorConfigSupport = true,
					},
					MsBuild = {},
					RenameOptions = {},
					RoslynExtensionsOptions = {},
					Sdk = {
						IncludePrereleases = true,
					},
				},
			})
		end,
	},
}
