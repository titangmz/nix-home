# Command-line extras for personal machines. Servers keep the core tools in modules/cli.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cowsay
    lolcat
    rustscan
    tor
    torsocks
  ];
}
