-- Setup cmp capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if ok then
	capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

-- Configure individual LSP servers with capabilities
vim.lsp.config("lua_ls", {
	capabilities = capabilities,
	on_init = function(client)
		if client.workspace_folders then
			local path = client.workspace_folders[1].name
			if vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc") then
				return
			end
		end

		client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua or {}, {
			runtime = { version = "LuaJIT" },
			workspace = {
				checkThirdParty = false,
				library = { vim.env.VIMRUNTIME },
			},
		})
	end,
	settings = { Lua = {} },
})

vim.lsp.config("nil_ls", { capabilities = capabilities })

vim.lsp.config("nixd", {
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

vim.lsp.config("ts_ls", { capabilities = capabilities })
vim.lsp.config("terraformls", { capabilities = capabilities })
vim.lsp.config("gopls", { capabilities = capabilities })
vim.lsp.config("astro", { capabilities = capabilities })
vim.lsp.config("ruby_lsp", { capabilities = capabilities })
vim.lsp.config("sqls", { capabilities = capabilities })
vim.lsp.config("phpactor", {
	capabilities = capabilities,
	cmd = { "phpactor", "language-server" },
	filetypes = { "php" },
	root_markers = { "composer.json", ".git" },
})
vim.lsp.config("html", {
	capabilities = capabilities,
	filetypes = { "html", "handlebars", "html.handlebars", "html.hbs" },
})
vim.lsp.config("omnisharp", {
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
vim.lsp.config("glsl_analyzer", { capabilities = capabilities })

-- Set up LSP keymaps on attach
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local bufnr = args.buf
		local opts = { buffer = bufnr }

		-- Disable LSP formatting in favor of conform.nvim if you use it
		if client then
			client.server_capabilities.documentFormattingProvider = false
			client.server_capabilities.documentRangeFormattingProvider = false
		end

		-- Keymaps
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>cd", vim.lsp.buf.declaration, opts)
	end,
})

-- Enable the LSP servers
vim.lsp.enable({
	"lua_ls",
	"nil_ls",
	"nixd",
	"ts_ls",
	"terraformls",
	"gopls",
	"astro",
	"ruby_lsp",
	"sqls",
	"html",
	"omnisharp",
	"glsl_analyzer",
  "phpactor"
})
