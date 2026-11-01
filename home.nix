{
  imports = [
    ./profiles/xray.nix
    ./modules/scripts
    ./modules/cli
    ./modules/shell
    ./modules/git
    ./modules/tmux
    ./modules/development
    ./modules/chat
    ./modules/ghostty
    ./modules/v2rayn
    ./modules/proxychains
    ./modules/neovim
  ];

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
