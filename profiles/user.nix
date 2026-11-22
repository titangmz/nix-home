# Who this configuration belongs to. Home Manager, the NixOS module, and the
# flake checks import this file; nothing else hard-codes the identity.
# user.default.nix holds the tracked values. A gitignored user.local.nix, when
# present, overrides any of them for this checkout.
let
  local = ./user.local.nix;
in
import ./user.default.nix // (if builtins.pathExists local then import local else { })
