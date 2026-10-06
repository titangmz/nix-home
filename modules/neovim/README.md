# Neovim

Nixvim configuration for editing, navigation, UI, Git, languages, the workspace layout, and the AI CLI.

`pcall(require, "local")` loads an optional `lua/local.lua` from the Neovim config when that file exists.

Blink completion uses Insert-mode Ctrl-e to accept and Ctrl-q to dismiss. The workspace keeps one shell for both views. `Space tt` opens its floating input. Cargo uses that shell. Lazygit is a separate floating overlay.
