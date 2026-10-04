# Neovim workspace

Neovim starts in the Code layout with Neo-tree and the editor. Press Space and
pause to discover mappings, or use `Space fk` to search them.

## Keymaps

| Keys | Action |
| --- | --- |
| `Space z` | Toggle editor-only Focus and restore the previous arrangement |
| `Space l1` / `l2` / `l3` / `l4` | Focus / Code / Git Review / Full |
| `Space ll` / `Space lr` | Choose a layout / return from Focus or Review |
| `Space e` / `Space E` | Toggle file tree / reveal current file |
| `Space ff` / `fg` / `fb` | Find files / search text / find buffers |
| `Space fF` / `Space fG` | Include hidden and ignored files / text |
| `Space tt` / `Space to` | Focused shell popup / read-only bottom output |
| `Space aa` / `af` / `ap` | Toggle Codex / insert file context / choose prompt |
| Visual `Space av` | Insert selected code into Codex |
| `Space gg` / `gd` / `gh` | Lazygit / review changes / file history |
| `Space gp` / `gs` / `gu` / `gR` | Preview / stage / undo stage / reset hunk |
| `Space gb` / `[h` / `]h` | Toggle line blame / previous / next hunk |
| `Space ca` / `cr` / `cf` / `ct` | Code action / rename / format / format-on-save |
| `Space cd` / `Space xx` | Line / workspace diagnostics |
| `gd` / `gr` / `K` / `[d` / `]d` | Definition / references / hover / diagnostics |
| `Space rr` / `rc` / `rt` | Cargo run / check / test |
| `Space wv` / `ws` / `wc` / `w=` | Split / split / close / equalize |
| `Space w>` / `w<` / `w+` / `w-` | Resize editor panes |
| `Space bn` / `bd` / `bs` | New / close / save buffer |
| `Tab` / `Shift-Tab` | Next / previous buffer in editor windows |
| `Ctrl-h/j/k/l` | Move between panes, including terminal mode |
| Insert `Ctrl-e` / `Ctrl-q` | Accept / dismiss completion suggestions |
| Double Escape | Close shell popup; normal mode in AI/Lazygit |

Blink completion uses Ctrl-n/Ctrl-p to select suggestions and Ctrl-Space to open
the menu. Ctrl-e accepts the selected suggestion, or the first when none is
selected; Ctrl-q dismisses it. Both retain built-in behavior when completion is
inactive. Ctrl-y also accepts suggestions.

## Layouts and processes

Full shows the tree, editor, Codex on the right, and read-only shell output
below. On narrow screens the tree hides first; Codex and shell output share the
bottom slot. `Space to` selects shell output and `Space aa` selects Codex.
Widening restores requested panes.

Focus preserves splits, unsaved buffers, cursor positions, and jobs. Review uses
a separate Diffview tab; `Space lr` returns to the editor. Lazygit uses a
centered floating window; `q` closes it. Tool pane sizes are remembered during
the session.

One persistent native terminal buffer is shared by the shell popup and bottom
output view. `Space tt` focuses the popup and double Escape hides it without
stopping the shell. The bottom view allows scrolling and copying but blocks
terminal input. The shell starts at the first workspace root and keeps its
working directory. Cargo tasks use the same shell, retain output, and reject a
second task while one is running; use Ctrl-C in the popup to stop one.

Command equivalents are `:WorkspaceLayout [focus|code|review|full]` and
`:WorkspaceRestore`. Each workspace tab fixes its root at the Git root, or the
opened directory outside Git. Layouts and processes are not restored across
editor restarts.

## AI and languages

Run `codex login` once after applying. Credentials remain in Codex's local
storage outside Nix. Context mappings insert text into the Codex prompt; submit
with Enter. Unsaved editor changes remain intact when Codex modifies disk files.
The integration is CLI-only and does not require Copilot or another API
subscription.

Rust uses rust-analyzer, Clippy, and rustfmt. Nix uses nixd and nixfmt. Shell,
JSON, YAML, and TOML have language servers; shell, configuration files, and
Markdown have Nix-managed formatters. Formatting runs on save and `Space ct`
toggles it.

The flake check exercises layout restoration, the shared shell and terminal
views, popup closing, narrow screens, Git review, fake-AI context delivery, and
real Rust/Nix formatting. Authenticated AI and native macOS runtime behavior
require separate interactive verification.
