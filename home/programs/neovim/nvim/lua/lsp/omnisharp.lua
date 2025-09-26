return {
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
}
