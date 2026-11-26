{ pkgs, ... }:
{
  home.packages = [ pkgs.serie ];

  xdg.configFile."serie/config.toml".text = ''
    [core.option]
    protocol = "kitty-unicode"
  '';
}
