# Profiles a machine can switch to, and the systems each one supports.
# The flake builds `<profile>-<system>` from this table, and scripts/switch.sh reads it.
# Other files in this directory are layers that profiles import, plus user.nix,
# the identity they share.
let
  linux = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  # Apple Silicon only: nixvim 26.05 dropped Intel Macs, and nixpkgs drops them after 26.05.
  darwin = [ "aarch64-darwin" ];
in
{
  server = linux ++ darwin;
  pc = [ "x86_64-linux" ];
  mac = darwin;
  nixos = [ "x86_64-linux" ];
}
