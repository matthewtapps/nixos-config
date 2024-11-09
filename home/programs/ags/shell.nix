{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
      nativeBuildInputs = with pkgs.buildPackages; [ python312 lazygit nodejs_22 eslint_d nodePackages.eslint nodePackages.typescript-language-server nodePackages.prettier ];
    }
