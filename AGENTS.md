# Working rules

Read [docs/rules.md](docs/rules.md) before changing configuration. Module details belong in the README next to that module.

Keep portable Home Manager a subset of the NixOS desktop. Keep colors, opacity, and blur in `modules/theme`.

Validate with `nix fmt` and `nix flake check "path:$PWD"`.
