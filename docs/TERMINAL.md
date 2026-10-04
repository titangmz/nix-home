# WezTerm and tmux

## WezTerm

Install WezTerm separately, then apply Home Manager. Its configuration is
managed at `modules/wezterm/wezterm.lua` and installed through
`xdg.configFile`.

The configuration uses built-in Catppuccin Mocha, bundled JetBrains Mono with
Nerd Font and emoji fallbacks, 13-point text, padding, 10,000 lines of
scrollback, quiet bells, 90% background opacity, and a tab bar that hides when
only one tab is open. macOS uses a blur radius of 16; Linux blur depends on the
compositor. New shells start Nix-managed Zsh directly.

Press Ctrl-Shift-a, release it, then press a key within one second:

| Key | Action |
| --- | --- |
| `v` / `s` | Split side by side / top and bottom |
| `h/j/k/l` | Focus left / down / up / right pane |
| `z` / `x` | Toggle pane zoom / close pane with confirmation |
| `r`, then `h/j/k/l` | Resize; Enter/Escape exits, or wait three seconds |
| `t` / `n` / `p` / `w` | New tab / next / previous / tab navigator |
| `y` / `f` / `Space` | Copy mode / search scrollback / Quick Select |

Default shortcuts remain available. Ctrl-Shift-C/V copies and pastes,
Ctrl-Shift-P opens the command palette, and Ctrl-Shift-R reloads configuration.
On macOS, Cmd-C/V and Cmd-plus/minus work too. Ctrl-Space still reaches Neovim;
tmux's Ctrl-a prefix remains available.

Validate the generated configuration with:

```bash
wezterm --config-file ~/.config/wezterm/wezterm.lua show-keys --lua
```

## Tmux

Tmux uses Ctrl-a as its prefix and `tmux-256color` inside panes. It advertises
RGB for WezTerm's outer `xterm-256color` and `wezterm` terminals.

Update an existing server without stopping its jobs:

```bash
tmux source-file ~/.config/tmux/tmux.conf
```

Detach with Ctrl-a then `d` and reattach with `tmux attach` to refresh client
terminal capabilities. Verify RGB with:

```bash
tmux list-clients -F '#{client_termfeatures}'
```
