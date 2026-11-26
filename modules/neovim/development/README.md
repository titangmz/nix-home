# Neovim development tooling

Rust, TypeScript, Go, and Nix language support beyond highlighting and formatting, and one workflow for Rust and TypeScript: run, test, check, and debug from the editor with the same keys. Also syntax parsers for every language; without this module the editor installs parsers for about 35 common ones.

`modules/neovim` does not import this; `profiles/workstation.nix` does. Servers keep the editor, the Bash, JSON, YAML, and TOML language servers, and the other formatters, without the Rust compiler and LLVM.

## Toolchain

The editor carries rust-analyzer, rustc, Cargo, clippy, rustfmt, Node, and `tsc`, placed after the inherited `PATH`. A project that brings its own toolchain, through a direnv shell, a rustup override, or a Node version manager, is checked, formatted, and run with that one; the editor's is the fallback.

rust-analyzer runs clippy on save and builds in `target/rust-analyzer`, so it never holds the build lock a task is waiting for. That costs a second copy of the build artifacts.

## Tasks

A task is one command in its own terminal, docked under the editor. Starting one saves every modified file first, which also formats them, and leaves the cursor where it is. The statusline shows the task while it runs and how it ended. Starting another task replaces a running one.

`run` keeps its output open. Checks and tests stay out of the way: their pane appears only if they take more than a moment, and closes again when they pass. A failure opens the pane and loads the compiler errors, warnings, and panics into the quickfix list, so `]q` and `[q` step through them.

The buffer's filetype picks the language. In any other file, the nearest `Cargo.toml` or `package.json` above it does.

The maintained [workstation shortcut reference](../README.md#workstation-workflow) lists the run, test, task-output, and Rust-specific keys.

### Rust

rust-analyzer decides what `Space rr` and `Space rt` run, so they pick the right package, binary, and test in any workspace. Outside a Rust buffer, or before the analyzer is ready, they run plain `cargo run` and `cargo test` from the nearest `Cargo.toml`.

[rustaceanvim](https://github.com/mrcjkb/rustaceanvim) owns the rust-analyzer client; `:RustLsp` has the rest of its commands. [crates.nvim](https://github.com/saecki/crates.nvim) shows versions and features in `Cargo.toml`.

### TypeScript

The project decides the tools. Its lockfile names the package manager (Bun, pnpm, Yarn, else npm), and `node_modules/.bin` names the rest, looked up through the parent directories so monorepos work.

- A file runs with Bun in a Bun project, with the project's `tsx` when it has one, and otherwise with Node, which runs TypeScript by stripping the types.
- Tests run with Bun, Vitest, or Jest, whichever the project has; then the package's `test` script; then `node --test`.
- Files are formatted with Biome when the project has a `biome.json` and Biome installed, otherwise with Prettier. The project's own copy of either is used before the editor's.

[vtsls](https://github.com/yioneko/vtsls) is the language server. The ESLint server attaches where the project has an ESLint configuration.

## Debugging

nvim-dap is fetched from [GitHub](https://github.com/mfussenegger/nvim-dap) instead of the Codeberg source used by nixpkgs. The override retains nixpkgs’ pinned revision and content hash. A scoped plugin override makes dap-view use the same nvim-dap dependency, so it does not pull in the Codeberg source.

`Space rd` starts what is under the cursor under the debugger: in Rust it builds the binary or test first, in TypeScript it launches the current file with Node, or the project's `tsx`. The panel with scopes, watches, breakpoints, threads, and the REPL opens with the session.

The [debugging shortcut reference](../README.md#debugging) lists the bindings.

TypeScript uses [js-debug](https://github.com/microsoft/vscode-js-debug) on every system. For Rust, Linux uses codelldb from nixpkgs. On macOS the nixpkgs debuggers lose the program after starting it, so the editor runs Apple's `lldb-dap` through `xcrun`; debugging there needs the Xcode Command Line Tools (`xcode-select --install`). The program's output appears in the panel's REPL.
