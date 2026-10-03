{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
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
