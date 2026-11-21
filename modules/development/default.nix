{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    stdenv.cc
    rustc
    cargo
    rust-analyzer
    rustPlatform.rustLibSrc
    clippy
    rustfmt
    go
    gopls
    fnm
    # Node 26 is the active LTS; npm ships with it. pnpm runs on the same Node.
    nodejs_26
    (pnpm.override {
      nodejs = nodejs_26;
      nodejs-slim = nodejs-slim_26;
    })
  ];

  programs.pyenv = {
    enable = true;
    rootDirectory = "${config.home.homeDirectory}/.pyenv";
    # Interactive Bash hands off to Zsh, which initializes pyenv once.
    enableBashIntegration = false;
  };
}
