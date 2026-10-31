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
    fnm
  ];

  programs.pyenv = {
    enable = true;
    rootDirectory = "${config.home.homeDirectory}/.pyenv";
    # Interactive Bash hands off to Zsh, which initializes pyenv once.
    enableBashIntegration = false;
  };
}
