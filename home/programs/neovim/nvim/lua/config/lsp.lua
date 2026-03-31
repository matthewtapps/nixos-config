-- Setup cmp capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if ok then
	capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

-- Configure individual LSP servers with capabilities
vim.lsp.config("nixd", {
	capabilities = capabilities,
	cmd = { "nixd" },
	filetypes = { "nix" },
	root_markers = { "flake.nix", ".git" },
	settings = {
		nixd = {
			nixpkgs = {
				expr = "import <nixpkgs> { }",
			},
			options = {
				nixos = {
					expr = "(builtins.getFlake \"/home/matt/nixos-config\").nixosConfigurations."
						.. vim.fn.hostname()
						.. ".options",
				},
			},
		},
	},
})

-- Auto-generate .nixd.json so nixd uses the project's pinned nixpkgs.
-- We read flake.lock and build a locked github:owner/repo/rev reference,
-- which nixd can evaluate in pure mode (unlike a raw local path).
-- The file is regenerated whenever the lock changes (e.g. after nix flake update).
vim.api.nvim_create_autocmd("FileType", {
	pattern = "nix",
	callback = function(ev)
		local root = vim.fs.root(ev.buf, "flake.nix")
		if not root then return end

		-- Parse flake.lock to get the pinned nixpkgs commit
		local nixpkgs_expr = "import <nixpkgs> { }"
		local lf = io.open(root .. "/flake.lock", "r")
		if lf then
			local ok, lock = pcall(vim.json.decode, lf:read("*a"))
			lf:close()
			-- Follow root → nixpkgs node → locked attrs
			local inputs = ok and lock.nodes and lock.nodes.root and lock.nodes.root.inputs
			local node_name = inputs and inputs.nixpkgs
			local locked = node_name and lock.nodes[node_name] and lock.nodes[node_name].locked
			if locked and locked.type == "github" and locked.rev then
				nixpkgs_expr = ('import (builtins.getFlake "github:%s/%s/%s") { }')
					:format(locked.owner, locked.repo, locked.rev)
			end
		end

		local config = vim.json.encode({
			nixpkgs = { expr = nixpkgs_expr },
			options = {
				nixos = {
					expr = "(builtins.getFlake \"/home/matt/nixos-config\").nixosConfigurations."
						.. vim.fn.hostname() .. ".options",
				},
			},
		})

		-- Only write + restart nixd if content differs (avoids churn on every file open)
		local nixd_path = root .. "/.nixd.json"
		local existing = ""
		local ef = io.open(nixd_path, "r")
		if ef then existing = ef:read("*a"); ef:close() end
		if existing ~= config then
			local wf = io.open(nixd_path, "w")
			if wf then
				wf:write(config)
				wf:close()
				vim.schedule(function() vim.cmd("LspRestart nixd") end)
			end
		end
	end,
})

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


vim.lsp.config("ts_ls", { capabilities = capabilities })
vim.lsp.config("terraformls", { capabilities = capabilities })
vim.lsp.config("gopls", {
	capabilities = capabilities,
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
	root_markers = { "go.work", "go.mod", ".git" },
})
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
		local bufnr = args.buf

		-- Don't attach LSP to oil buffers (oil:// URI scheme causes errors)
		if vim.bo[bufnr].filetype == "oil" then
			vim.lsp.buf_detach_client(bufnr, args.data.client_id)
			return
		end

		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local opts = { buffer = bufnr }

		-- Disable LSP formatting in favor of conform.nvim if you use it
		if client then
			client.server_capabilities.documentFormattingProvider = false
			client.server_capabilities.documentRangeFormattingProvider = false
		end

		-- Keymaps
		vim.keymap.set("n", "<leader>li", "<cmd>LspInfo<cr>", { buffer = bufnr, desc = "LSP Info" })
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>cd", vim.lsp.buf.declaration, opts)
	end,
})

-- Enable the LSP servers
vim.lsp.enable({
	"lua_ls",
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
