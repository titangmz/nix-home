{ pkgs, ... }:
{
  home.packages = [ pkgs.profanity ];
  xdg.configFile."profanity/profrc".source = ./profrc;
}
