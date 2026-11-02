{ pkgs, ... }:
{
  # On macOS, Home Manager copies the app into ~/Applications/Home Manager Apps.
  home.packages = [ (pkgs.callPackage ./package.nix { }) ];
}
