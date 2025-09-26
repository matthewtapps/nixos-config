return {
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
}
