return {
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				css = { "biome" },
				html = { "biome" },
				svg = { "biome" },
				elixir = { "mix format" },
				fish = { "fish_indent" },
				javascript = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				lua = { "stylua" },
				nix = { "nixfmt" },
				python = { "black" },
				sh = { "shfmt" },
				svelte = { "prettier" },
				typescript = { "prettier" },
				rust = { "rustfmt" },
				go = { "go fmt" },
				astro = { "prettier" },
				ruby = { "rufo" },
				terraform = { "terraform fmt" },
				tf = { "terraform_fmt" },
				sql = { "sqlfluff" },
				pgsql = { "sqlfluff" },
				html = { "djlint" },
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
					command = "dotnet-sharpier",
					args = { "--write-stdout" },
				},
			},
		},
	},
}
