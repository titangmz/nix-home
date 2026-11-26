# Neovim

Nixvim configuration for editing, navigation, UI, Git, languages, and the workspace layout.

Keep this reference current whenever our Neovim customizations or hotkeys change. Keys below are available on every profile unless marked workstation-only. `Space` is the leader: press it, then the listed keys in sequence. Keys use Normal mode unless another mode is stated. Uppercase letters are distinct shortcuts.

`development` adds the Rust and TypeScript workflow (language servers, run, test, and debug keys, a task pane), Go and gopls, nixd, and every syntax parser. It is not imported by `default.nix`; only `profiles/workstation.nix` imports it, so servers do without it. [Development details](development/README.md) explain toolchain selection and task behavior.

Apply configuration changes with `just switch`, then restart Neovim. Pause after `Space` to see which-key's available shortcuts, or use `Space fk` to search keymaps.

`pcall(require, "local")` loads an optional `lua/local.lua` from the Neovim config when that file exists.

Blink completion accepts with Insert-mode `Tab` (or Ctrl-e, or Ctrl-y) and dismisses with Ctrl-q. With no menu open, `Tab` and `Shift-Tab` move between snippet fields, and otherwise `Tab` indents.

## Buffers and editing

| Shortcut | Action |
| --- | --- |
| `Tab` / `Shift-Tab`, `]b` / `[b` | Next / previous buffer |
| `Space bn` | New empty buffer |
| `Space bd` / `Space bo` | Close this buffer / other buffers |
| `Space bs` | Save buffer |
| `Ctrl-s` | Save in Normal, Insert, or Visual mode; Insert and Visual mode return to Normal |
| `Esc` | Clear search highlighting in Normal mode |
| `<` / `>` in Visual mode | Indent and keep the selection |
| `J` / `K` in Visual mode | Move selected lines down / up |

Relative line numbers, persistent undo, the system clipboard, mouse support, automatic pairs, and surround editing are enabled. Indentation defaults to two spaces, with indent-o-matic detecting existing indentation. Searches ignore case unless the pattern contains uppercase letters. Syntax folding starts open.

## Windows

These controls manage Neovim splits; tmux panes have their [own controls](../tmux/README.md).

| Shortcut | Action |
| --- | --- |
| `Ctrl-h` / `Ctrl-j` / `Ctrl-k` / `Ctrl-l` | Focus left / down / up / right, including from terminal input |
| `Space wv` / `Space \|` | Split vertically, opening to the right |
| `Space ws` / `Space _` | Split horizontally, opening below |
| `Space wc` | Close current window |
| `Space w=` | Equalize window sizes |
| `Space w>` / `Space w<` | Widen / narrow by two columns |
| `Space w+` / `Space w-` | Increase / decrease height by two rows |
| `Ctrl-Right` / `Ctrl-Left` | Widen / narrow by four columns |
| `Ctrl-Up` / `Ctrl-Down` | Increase / decrease height by two rows |
| `Space l1` / `Space l2` | Main layout / Git review layout |

## Find and navigate

| Shortcut | Action |
| --- | --- |
| `Space Space` | Toggle the file tree at the current file |
| `Space ff` / `Space fF` | Find project files / include hidden and ignored files |
| `Space fg` / `Space fG` | Search project text / include hidden and ignored files |
| `Space fw` | Search the word under the cursor |
| `Space fb` | Find open buffers |
| `Space fs` / `Space fS` | Find document / workspace symbols |
| `Space fc` / `Space fh` | Find commands / command history |
| `Space fk` | Find keymaps |
| `Space fr` / `Space fR` | Recent files / resume the last picker |
| `Space fd` | Find workspace diagnostics |
| `-` / `Space -` | Edit the parent directory with Oil, in place / floating |

In Telescope's input: `Ctrl-j` / `Ctrl-k` move the selection, `Ctrl-v` / `Ctrl-x` open in a vertical / horizontal split, and `Esc` closes the picker.

Oil edits directories as buffers: change names or add entries, then save to apply. Its configured controls are `Ctrl-v` / `Ctrl-x` to open in a vertical / horizontal split, `Ctrl-r` to refresh, `Backspace` for the parent, `gh` to toggle hidden files, and `q` to close.

## Code and diagnostics

Language navigation needs an attached language server. Every profile includes Bash, JSON, YAML, and TOML servers; workstations add development language support.

| Shortcut | Action |
| --- | --- |
| `gd` / `gD` | Go to definition / declaration |
| `gr` / `gi` | Find references / go to implementation |
| `K` | Hover documentation |
| `Space ca` / `Space cr` | Code actions / rename symbol |
| `Space cf` | Format buffer, falling back to the language server |
| `Space ct` | Toggle format on save for this Neovim session |
| `Space cd` | Show diagnostics for this line |
| `[d` / `]d` | Previous / next diagnostic |
| `Space xx` | Toggle the Trouble workspace diagnostics list |

Format on save uses configured formatters with a two-second timeout. The base editor formats Nix, shell, JSON, YAML, Markdown, and TOML; development adds more languages. Set `vim.b.disable_autoformat = true` to disable it for one buffer.

## Git

| Shortcut | Action |
| --- | --- |
| `Space gg` | Open Lazygit in a floating terminal |
| `Space gd` | Open Git review (same as `Space l2`) |
| `Space gh` | Open the current file's Git history |
| `Space gb` | Toggle current-line blame |
| `Space gp` | Preview the current hunk |
| `Space gs` / `Space gu` | Stage the current hunk / undo its staging |
| `Space gR` | Reset the current hunk, discarding its changes |
| `[h` / `]h` | Previous / next hunk |

## Workstation workflow

These shortcuts are available on `pc`, `mac`, and `nixos`. Starting a task saves modified files first. The buffer's filetype, or the nearest `Cargo.toml` or `package.json`, selects the workflow. See [development details](development/README.md) for runner selection and task output behavior.

| Shortcut | Rust | TypeScript and JavaScript |
| --- | --- | --- |
| `Space rr` | Run the binary or test under the cursor | Run the current file, or the test under the cursor in a test file |
| `Space rt` | Test at cursor: test, module, or package | Test the enclosing `it`, `test`, or `describe`; outside a test file, run every test |
| `Space rT` | Test the whole workspace | Run every test |
| `Space rc` | Clippy on the workspace and every target | `tsc --noEmit`, then ESLint when configured |
| `Space rs` | — | Pick a `package.json` script |
| `Space rd` | Currently warns: debugging is disabled | Currently warns: debugging is disabled |

| Shortcut | Action |
| --- | --- |
| `Space rl` / `Space rx` | Rerun the last task / stop the running task |
| `Space ri` | Focus task input; `Ctrl-/` returns to the editor |
| `Space to` | Toggle task output |
| `Space re` / `Space rE` | Rust: expand macro / explain the error on this line |
| `Space uh` | Toggle inlay hints when supported by the attached language server |
| `]q` / `[q` | Next / previous quickfix entry (standard Neovim keys, useful after a failed task) |

### Debugging (currently disabled)

`debugger = false` in `development/default.nix` disables the debugger plugins and all `Space d` bindings. `Space rd` remains mapped but only warns. These controls apply when debugging is enabled again:

| Shortcut | Action when enabled |
| --- | --- |
| `Space rd` | Debug at cursor |
| `Space db` / `Space dc` | Toggle breakpoint / continue |
| `Space do` / `Space di` / `Space dO` | Step over / into / out |
| `Space dx` / `Space du` | End session / toggle debugger panel |

The [debugging notes](development/README.md#debugging) describe the dependency issue and platform requirements.

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

The highlighted row marks your place, so the cursor is hidden while the tree has focus; it returns for the command line and on leaving the tree. Every folder has its own row. Inside the tree: `Enter` or `o` opens a file or opens and closes a folder, `l` opens, `h` collapses, `v`/`s` open in a vertical or horizontal split, `t` opens in a new tab, `P` preview, `a` add and `A` add a folder (the prompt starts with the folder's path from the project root; edit it to create anywhere, end a name with `/` for a folder, or type `x/y/file.md` to create the folders on the way), `c` copy to a prompted path, `m` move to a prompted path, `r` rename, `d` delete, `y`/`x`/`p` copy, cut, paste, `Y` copy the path, `H` toggle hidden files, `/` filter, `.` set root, `Backspace` go up, `z`/`Z` collapse or expand everything, `<`/`>` switch between filesystem, buffers, and Git status sources, `q` close, `?` help.

Telescope places its preview beside the results on wide windows, below them on narrow ones, and drops it when the window is too short. The statusline hides the branch, project, language server, and layout label as the window narrows.
