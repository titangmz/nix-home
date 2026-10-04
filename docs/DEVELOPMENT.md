# Development and maintenance

Format and validate repository changes from the checkout:

```bash
nix fmt
nix flake check "path:$PWD"
nix flake check "path:$PWD" --all-systems --no-build
```

The first check builds native checks, including Home Manager profiles, script
tests, and Neovim behavior. The all-systems command evaluates the Linux and
Darwin outputs without building non-native results. Evaluation alone does not
prove native runtime support.

Full NixOS validation uses the target machine's local configuration:

```bash
just switch-nixos --dry-run
```

Unlike `nix flake check`, `nix fmt` passes positional arguments to the
formatter.

List operational recipes with `just`. Benchmark a real portable Home Manager
activation with:

```bash
just benchmark-switch
```

This runs ten real `just switch` activations with Hyperfine and shows their
output. Cached builds make later runs faster.

Native macOS builds, authenticated AI behavior, and other platform-specific
runtime behavior require separate verification on those systems.
