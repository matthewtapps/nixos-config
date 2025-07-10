return {
	{ "neovim/nvim-lspconfig" },
	{ "hrsh7th/nvim-cmp" },
	{ "hrsh7th/cmp-nvim-lsp" },
	{ "hrsh7th/cmp-buffer" },
	{ "hrsh7th/cmp-path" },
	{ "hrsh7th/cmp-cmdline" },
	{ "L3MON4D3/LuaSnip" },
	{ "saadparwaiz1/cmp_luasnip" },
	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v3.x",
		config = function()
			local lsp_zero = require("lsp-zero")
			lsp_zero.extend_lspconfig()
			local cmp = require("cmp")
			local cmp_action = require("lsp-zero").cmp_action()

			-- Setup completion
			cmp.setup({
				sources = {
					{ name = "nvim_lsp" },
					{ name = "buffer" },
					{ name = "path" },
					{ name = "luasnip" },
				},
				mapping = cmp.mapping.preset.insert({
					-- Navigate completion menu
					["<C-k>"] = cmp.mapping.select_prev_item(),
					["<C-j>"] = cmp.mapping.select_next_item(),

					-- Trigger completion
					["<C-Space>"] = cmp.mapping.complete(),

					-- Close completion
					["<C-e>"] = cmp.mapping.close(),

					-- Accept completion
					["<CR>"] = cmp.mapping.confirm({ select = false }),
					["<Tab>"] = cmp.mapping.confirm({ select = true }),

					-- Navigate snippet placeholders
					["<C-f>"] = cmp_action.luasnip_jump_forward(),
					["<C-b>"] = cmp_action.luasnip_jump_backward(),

					-- Scroll documentation
					["<C-u>"] = cmp.mapping.scroll_docs(-4),
					["<C-d>"] = cmp.mapping.scroll_docs(4),
				}),
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				formatting = {
					format = function(entry, vim_item)
						-- Kind icons
						local kind_icons = {
							Text = "󰉿",
							Method = "󰆧",
							Function = "󰊕",
							Constructor = "",
							Field = "󰜢",
							Variable = "󰀫",
							Class = "󰠱",
							Interface = "",
							Module = "",
							Property = "󰜢",
							Unit = "󰑭",
							Value = "󰎠",
							Enum = "",
							Keyword = "󰌋",
							Snippet = "",
							Color = "󰏘",
							File = "󰈙",
							Reference = "󰈇",
							Folder = "󰉋",
							EnumMember = "",
							Constant = "󰏿",
							Struct = "󰙅",
							Event = "",
							Operator = "󰆕",
							TypeParameter = "",
						}

						vim_item.kind = string.format("%s %s", kind_icons[vim_item.kind], vim_item.kind)
						vim_item.menu = ({
							nvim_lsp = "[LSP]",
							luasnip = "[Snippet]",
							buffer = "[Buffer]",
							path = "[Path]",
						})[entry.source.name]

						return vim_item
					end,
				},
				experimental = {
					ghost_text = true,
				},
			})

			-- Setup completion for search
			cmp.setup.cmdline("/", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			-- Setup completion for commands
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
				}),
			})

			-- LSP Zero on_attach
			lsp_zero.on_attach(function(client, bufnr)
				-- Disable LSP formatting in favor of conform.nvim
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false

				-- Set up buffer local keymaps
				local opts = { buffer = bufnr }
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
				vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
				vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, opts)
				vim.keymap.set("n", "<leader>cd", vim.lsp.buf.declaration, opts)
			end)

			-- Global handler for LSP errors
			vim.lsp.handlers["window/showMessage"] = function(_, result, ctx)
				local client = vim.lsp.get_client_by_id(ctx.client_id)
				local lvl = ({
					vim.log.levels.ERROR,
					vim.log.levels.WARN,
					vim.log.levels.INFO,
					vim.log.levels.DEBUG,
				})[result.type]
				vim.notify(result.message, lvl, { title = client.name })
			end

			-- Configure LSP servers with cmp capabilities
			local lspconfig = require("lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
			require("lspconfig").lua_ls.setup({ capabilities = capabilities })
			require("lspconfig").nil_ls.setup({ capabilities = capabilities })
			require("lspconfig").nixd.setup({
				capabilities = capabilities,
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
			require("lspconfig").ts_ls.setup({ capabilities = capabilities })
			require("lspconfig").terraformls.setup({ capabilities = capabilities })
			require("lspconfig").gopls.setup({ capabilities = capabilities })
			require("lspconfig").astro.setup({ capabilities = capabilities })
			require("lspconfig").ruby_lsp.setup({ capabilities = capabilities })
			require("lspconfig").sqls.setup({ capabilities = capabilities })
			require("lspconfig").htmx.setup({ capabilities = capabilities })
			require("lspconfig").html.setup({
				capabilities = capabilities,
				filetypes = { "html", "handlebars", "html.handlebars", "html.hbs" },
			})
			require("lspconfig").omnisharp.setup({
				capabilities = capabilities,
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
			require("lspconfig").glsl_analyzer.setup({})
		end,
	},
}
