# Neovim

Nixvim configuration for editing, navigation, UI, Git, languages, and the workspace layout.

`development` adds rust-analyzer, the Rust tools, nixd, and every syntax parser. It is not imported by `default.nix`; only `profiles/workstation.nix` imports it, so servers do without it.

`pcall(require, "local")` loads an optional `lua/local.lua` from the Neovim config when that file exists.

Blink completion uses Insert-mode Ctrl-e to accept and Ctrl-q to dismiss. The workspace keeps one shell for both views. `Space tt` opens its floating input. Cargo uses that shell. Lazygit is a separate floating overlay.

## Transparency

`neovim.transparent` in `modules/theme` clears the editor background so the terminal's glass shows through. Popups are clear as well, with a lavender rounded border: pickers, the file tree, completion, hover and diagnostic windows, which-key, notifications, Oil, Lazygit, and the shell popup. Neovim cannot blur; the terminal blurs the desktop behind its window, and a float with no fill still hides the code beneath it while `winblend` and `pumblend` stay 0. The smoke test checks both.

## Layouts

There are two. `Space l1` is the main layout: the editor, with the shell output docked below once `Space to` or a Cargo task shows it. `Space l2` opens the Git review (Diffview) in its own tab; `Space l1` closes it and returns to the editor with its splits and unsaved edits intact.

## File tree

The file tree is always a popup, like the Telescope pickers; it never docks as a sidebar. `Space Space` opens it at the current file. Opening a file from it closes it and shows the file in the editor; `q`, `Esc`, or `Space Space` again close it at any time. Space stays the leader inside the tree.

| Key | Action |
| --- | --- |
| `Space Space` | Toggle the file tree popup at the current file |
| `Space ff` / `Space fg` | Find files, search text |
| `-` / `Space -` | Oil: edit the parent directory as a buffer, in place or floating |
| `Ctrl-h/j/k/l` | Move between editor and terminal windows |
| `Ctrl-arrows` | Resize the current window |
| `Ctrl-s` | Save |

Inside the tree: `l`/`Enter` open, `h` collapse, `v`/`s` open in a vertical or horizontal split, `P` preview, `a` add (end with `/` for a directory), `r` rename, `d` delete, `y`/`x`/`p` copy, cut, paste, `Y` copy the path, `H` toggle hidden files, `/` filter, `.` set root, `Backspace` go up, `z`/`Z` collapse or expand everything, `q` close, `?` help.

Telescope places its preview beside the results on wide windows, below them on narrow ones, and drops it when the window is too short. The statusline hides the branch, project, language server, and layout label as the window narrows.
