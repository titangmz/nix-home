# Neovim development tooling

Rust and Nix language support beyond highlighting and formatting: rust-analyzer with clippy checks, rustfmt, the Rust compiler and Cargo for the analyzer, the nixd language server, and syntax parsers for every language. Without it the editor installs parsers for about 35 common languages.

`modules/neovim` does not import this; `profiles/workstation.nix` does. Servers keep the editor, the Bash, JSON, YAML, and TOML language servers, and the other formatters, without the Rust compiler and LLVM.
