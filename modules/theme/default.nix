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
    # Selected text and the highlighted row in pickers and the file tree:
    # lavender mixed into the base, light enough to stand out on the glass
    # background, dark enough that the text colour stays readable on it.
    selection = "525677";
  };
  # Shared glass opacity for Kitty, window title bars, and Waybar surfaces.
  opacity = "0.6";
  opacityHex =
    let
      scaled = builtins.floor ((builtins.fromJSON opacity) * 255 + 0.5);
      hex = lib.toHexString scaled;
    in
    if builtins.stringLength hex < 2 then "0${hex}" else hex;
  blur = {
    size = 5;
    passes = 3;
  };
  ghostty = {
    opacity = "0.75";
    blurRadius = 40;
  };
  # Neovim leaves its editor background clear so the terminal's glass shows
  # through, popups included.
  neovim.transparent = true;
  tokens = colors // {
    inherit opacity opacityHex;
    blurSize = toString blur.size;
    blurPasses = toString blur.passes;
  };
in
{
  inherit
    colors
    opacity
    opacityHex
    blur
    ghostty
    neovim
    ;
  flavor = "mocha";
  accent = "mauve";
  render = lib.replaceStrings (map (name: "@${name}@") (builtins.attrNames tokens)) (
    builtins.attrValues tokens
  );
  styleLua = ''
    return {
      opacity = ${opacity},
      opacityHex = "${opacityHex}",
      blur = { size = ${toString blur.size}, passes = ${toString blur.passes} },
      colors = {
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "    ${name} = \"${value}\",") colors
    )}
      },
    }
  '';
}
