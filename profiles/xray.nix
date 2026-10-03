{ config, pkgs, ... }:
{
  home.username = "xray";
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";

  programs.git.settings.user = {
    name = "Pedram Parsa";
    email = "titangmz@gmail.com";
  };
}
