{
  lib,
  pkgs,
  ...
}:
let
  v2rayn = pkgs.callPackage ./package.nix { };
in
{
  home.packages = [ v2rayn ];

  home.file."Applications/v2rayN.app" = lib.mkIf pkgs.stdenv.isDarwin {
    source = "${v2rayn}/Applications/v2rayN.app";
  };
}
