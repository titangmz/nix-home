# Layer: identity and the terminal core that every profile shares.
{ config, pkgs, ... }:
{
  imports = [
    ../modules/scripts
    ../modules/shell
    ../modules/cli
    ../modules/git
    ../modules/tmux
    ../modules/neovim
  ];

  home.username = "xray";
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";

  programs.git.settings.user = {
    name = "Pedram Parsa";
    email = "titangmz@gmail.com";
  };

  # Keep switches quiet; read announcements with `home-manager news`.
  news.display = "silent";

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
