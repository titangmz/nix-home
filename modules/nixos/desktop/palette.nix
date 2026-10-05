{ lib }:
let
  colors = {
    base = "1e1e2e";
    surface = "313244";
    border = "45475a";
    text = "cdd6f4";
    muted = "a6adc8";
    accent = "cba6f7";
    lavender = "b4befe";
    blue = "89b4fa";
    sapphire = "74c7ec";
    green = "a6e3a1";
    yellow = "f9e2af";
    red = "f38ba8";
    crust = "11111b";
    criticalBackground = "30202b";
  };
in
{
  inherit colors;
  flavor = "mocha";
  accent = "mauve";
  # Sources add their own #/rgba prefix and optional alpha channel.
  render = lib.replaceStrings (map (name: "@${name}@") (builtins.attrNames colors)) (
    builtins.attrValues colors
  );
}
