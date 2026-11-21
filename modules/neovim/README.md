# Neovim

Nixvim configuration for editing, navigation, UI, Git, languages, and the workspace layout.

`development` adds the Rust and TypeScript workflow (language servers, run, test, and debug keys, a task pane), Go and gopls, nixd, and every syntax parser. It is not imported by `default.nix`; only `profiles/workstation.nix` imports it, so servers do without it. Its README has the keys.

`pcall(require, "local")` loads an optional `lua/local.lua` from the Neovim config when that file exists.

Blink completion uses Insert-mode Ctrl-e to accept and Ctrl-q to dismiss.

## Terminal

There is one shell, in a popup. `Ctrl-/` opens it ready for typing, from Normal or Insert mode, and `Ctrl-/` again puts the editor back as it was: same window, same cursor, and still in Insert mode if that is where you were. `Space tt` does the same from Normal mode. The shell starts in the background when Neovim opens, so the first toggle shows a ready prompt, and it keeps running while hidden. `Esc Esc` leaves terminal input to scroll or copy; `q` there closes the popup. Typing `exit` ends the shell, and the next toggle starts a new one. Lazygit is a separate floating overlay.

Terminals without the extended key protocol send `Ctrl-/` as `Ctrl-_`, so both are mapped.

## Screen

Neovim draws nothing on its first row, so it never runs into a tmux status bar above it. Each editor window starts with a header row instead: blank when it is the only window, and naming its file in a pill once the window is split, the current one highlighted. Open buffers are listed as pills in the statusline at the bottom; `Tab` and `Shift-Tab` move between them.

## Markdown

render-markdown draws Markdown in the buffer: heading bars, checkboxes, tables, code blocks, and callouts. The line under the cursor shows the raw text. Ticked checkboxes are struck through. `Space um` switches between rendered and raw.

## Command line

[noice.nvim](https://github.com/folke/noice.nvim) shows `:` commands and `/` `?` searches in a rounded popup in the middle of the screen, with completion beneath it. Neovim's messages and errors go to the snacks notifier, so they look like every other notification in the top-right corner; only the "written" line after a save stays a quiet hint in the bottom-right corner. Output too long for a notification opens in a split. `Space un` lists past notifications. Hover and signature help stay with the LSP and blink.

## Transparency

`neovim.transparent` in `modules/theme` clears the editor background so the terminal's glass shows through. Popups are clear as well, with a lavender rounded border: pickers, the file tree, completion, hover and diagnostic windows, which-key, notifications, Oil, Lazygit, and the shell popup. Neovim cannot blur; the terminal blurs the desktop behind its window, and a float with no fill still hides the code beneath it while `winblend` and `pumblend` stay 0. The smoke test checks both.

Selected text, the current row in pickers and completion, and the file tree's cursor row all use the theme's `selection` colour, the same one Ghostty, Kitty, and tmux use for selected text.

## Layouts

The project root is the directory Neovim was started in, whether or not it is a Git repository; the tree, search, and terminals all work from it. Only a file opened from outside that directory brings its own root: its repository, or its folder when it has none.

There are two. `Space l1` is the main layout: the editor, with the task output docked below on workstations once a task or `Space to` shows it. `Space l2` opens the Git review (Diffview) in its own tab; `Space l1` closes it and returns to the editor with its splits and unsaved edits intact.

## File tree

The file tree is always a popup, like the Telescope pickers; it never docks as a sidebar. `Space Space` opens it at the current file. Opening a file from it closes it and shows the file in the editor; `q`, `Esc`, or `Space Space` again close it at any time. Space stays the leader inside the tree.

| Key | Action |
| --- | --- |
| `Space Space` | Toggle the file tree popup at the current file |
| `Space ff` / `Space fg` | Find files, search text |
| `-` / `Space -` | Oil: edit the parent directory as a buffer, in place or floating |
| `Ctrl-/` | Toggle the shell popup |
| `Ctrl-h/j/k/l` | Move between editor and terminal windows |
| `Ctrl-arrows` | Resize the current window |
| `Ctrl-s` | Save |

The highlighted row marks your place, so the cursor is hidden while the tree has focus; it returns for the command line and on leaving the tree. Every folder has its own row. Inside the tree: `Enter` opens a file or opens and closes a folder, `l` opens, `h` collapses, `v`/`s` open in a vertical or horizontal split, `P` preview, `a` add and `A` add a folder (the prompt starts with the folder's path from the project root; edit it to create anywhere, end a name with `/` for a folder, or type `x/y/file.md` to create the folders on the way), `r` rename, `d` delete, `y`/`x`/`p` copy, cut, paste, `Y` copy the path, `H` toggle hidden files, `/` filter, `.` set root, `Backspace` go up, `z`/`Z` collapse or expand everything, `q` close, `?` help.

Telescope places its preview beside the results on wide windows, below them on narrow ones, and drops it when the window is too short. The statusline hides the branch, project, language server, and layout label as the window narrows.
