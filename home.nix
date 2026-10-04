{
  imports = [
    ./profiles/xray.nix
    ./modules/cli
    ./modules/shell
    ./modules/git
    ./modules/tmux
    ./modules/wezterm
    ./modules/kitty
    ./modules/development
    ./modules/chat
    ./modules/neovim
  ];

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
