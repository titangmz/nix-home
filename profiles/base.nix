# Layer: identity and the terminal core that every profile shares.
{ config, pkgs, ... }:
let
  user = import ./user.nix;
in
{
  imports = [
    ../modules/scripts
    ../modules/shell
    ../modules/cli
    ../modules/git
    ../modules/tmux
    ../modules/neovim
    ../modules/zoxide
  ];

  home.username = user.username;
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";

  programs.git.settings.user = {
    inherit (user) name email;
  };

  # Keep switches quiet; read announcements with `home-manager news`.
  news.display = "silent";

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
