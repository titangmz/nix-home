# Repository structure

```text
flake.nix              Inputs (including Codex-only pin), systems, app, checks, formatter
flake.lock             Pinned dependency revisions
home.nix               Module imports and Home Manager state version
profiles/xray.nix      Username, home directory, Git identity
modules/
  cli/                 General CLI packages and Eza theme
  shell/               Zsh, Bash handoff, Atuin history, Starship, session paths
  git/                 Git and Lazygit settings
  tmux/                Managed plugins and terminal settings
  wezterm/             Configuration only; externally installed WezTerm
  development/         Rust tools, fnm, pyenv
  chat/                Profanity package and configuration
  neovim/              Editing/formatting, languages/LSP, navigation, UI, Git, keymaps
    workspace/         Layout controller, single shell with two views, Cargo tasks
    ai/                CLI-only Sidekick/Codex integration and context actions
switch.sh              Detect system and apply with the pinned CLI
justfile               Switch wrapper and single-run Hyperfine benchmark
tests/                 Switch-script tests and Neovim behavioral checks
```

Each module owns its packages, settings, and raw configuration files. Keep
plugin-specific Neovim mappings beside the plugin configuration; built-in
mappings belong in `modules/neovim/keymaps.nix`. Add top-level modules to
`home.nix`; keep personal settings in the profile.
`modules/neovim/editing.nix` owns Blink completion and its Insert-mode mappings:
`Ctrl-e` accepts suggestions and `Ctrl-q` dismisses them.

`modules/cli/default.nix` owns general CLI tools, including `jq`, `yq-go` (the
`yq` command), `just`, `hyperfine`, and `watchexec`; these need no additional
shell initialization.

`modules/shell/default.nix` owns Atuin's package and Zsh integration through
Home Manager. `Ctrl-r` opens local history search; the Up binding is preserved,
and automatic sync is disabled. Nix manages updates. Bash hands off to Zsh
without initializing Atuin.

`modules/wezterm` owns `~/.config/wezterm/wezterm.lua`, with built-in Catppuccin
Mocha, 90% background opacity, macOS blur, bundled fonts, and Ctrl-Shift-a
pane/tab shortcuts. Linux blur relies on compositor settings. It starts Nix-managed
Zsh directly and preserves default shortcuts and application Ctrl keys. WezTerm
itself is installed separately; this module adds no terminal package or plugin.

`modules/tmux` uses Ctrl-a as its prefix and `tmux-256color` inside panes.
Its `tmux.conf` advertises RGB for outer `xterm-256color`/`wezterm` terminals,
keeping Neovim's true-color Catppuccin palette consistent inside tmux.

Neovim Lua behavior lives beside its owning Nix module and is installed through
Nixvim `extraFiles`. The layout controller coordinates panes without rebuilding
editor splits; terminal and AI modules own process lifecycles. The terminal
module owns one native shell buffer, its interactive popup and read-only bottom
view, Cargo commands in that shell, and Lazygit's floating overlay. The bottom
view blocks terminal-input mode while preserving terminal colors and prompts.
Checks prepend
the generated extra-file runtime directory, matching Home Manager's installed
configuration. The separate `nixpkgs-codex` input uses the maintained 26.05 branch
for Intel macOS compatibility and supplies only Codex and its dependencies;
other packages retain the main Nixpkgs pin. The CLI-only Sidekick package has a
small local patch to guard callbacks when its terminal is hidden.

Run `nix fmt` from the checkout; its arguments are formatter paths/options,
whereas `nix flake check "path:$PWD"` takes an explicit flake reference.
