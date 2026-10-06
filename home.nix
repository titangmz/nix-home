{
  imports = [
    ./profiles/xray.nix
    ./modules/scripts
    ./modules/cli
    ./modules/shell
    ./modules/git
    ./modules/tmux
    ./modules/zed
    ./modules/development
    ./modules/chat
    ./modules/neovim
  ];

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
