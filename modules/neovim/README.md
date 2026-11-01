# Neovim

Nixvim configuration for editing, navigation, UI, Git, languages, and the workspace layout.

`ai` adds the Codex CLI and its dock. It is not imported by `default.nix`; `profiles/workstation.nix` imports it, so servers do without it. The workspace layout skips the AI dock when the module is absent.

`pcall(require, "local")` loads an optional `lua/local.lua` from the Neovim config when that file exists.

Blink completion uses Insert-mode Ctrl-e to accept and Ctrl-q to dismiss. The workspace keeps one shell for both views. `Space tt` opens its floating input. Cargo uses that shell. Lazygit is a separate floating overlay.
