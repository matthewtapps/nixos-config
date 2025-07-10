return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				mode = "",
				desc = "Format buffer",
			},
		},
		opts = {
			formatters_by_ft = {
				css = { "biome", "prettier" },
				html = { "prettier" },
				svg = { "prettier" },
				elixir = { "mix" },
				fish = { "fish_indent" },
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				lua = { "stylua" },
				nix = { "nixfmt" },
				python = { "black" },
				sh = { "shfmt" },
				svelte = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				rust = { "rustfmt" },
				go = { "gofmt" },
				astro = { "prettier" },
				ruby = { "rufo" },
				terraform = { "terraform_fmt" },
				tf = { "terraform_fmt" },
				sql = { "sqlfluff" },
				pgsql = { "sqlfluff" },
				["handlebars.html"] = { "djlint" },
				["html.hbs"] = { "djlint" },
				yaml = { "prettier" },
				tsx = { "prettier" },
				jsx = { "prettier" },
				js = { "prettier" },
				ts = { "prettier" },
				cs = { "csharpier" },
			},
			formatters = {
				sqlfluff = {
					command = "sqlfluff",
					args = { "format", "--dialect=postgres", "-" },
					stdin = true,
					cwd = function()
						return vim.fn.getcwd()
					end,
				},
				csharpier = {
					command = "dotnet-csharpier",
					args = { "--write-stdout" },
				},
				mix = {
					command = "mix",
					args = { "format", "-" },
					stdin = true,
				},
			},
		},
	},
}
