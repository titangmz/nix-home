{ pkgs, ... }:
{
  home.packages = [ pkgs.proxychains-ng ];

  home.file.".proxychains/proxychains.conf".source = ./proxychains.conf;
}
