# Tmux

Ctrl-a prefix, `tmux-256color` panes, and the Nix-managed Catppuccin plugin.

Terminal passthrough is enabled for visible panes, allowing applications such
as Serie to send image commands to the outer terminal. Serie uses Kitty Unicode
placeholders, which require Ghostty or Kitty even when running inside tmux.

## Controls

Keep this reference current whenever tmux controls change. A prefix shortcut means press Ctrl+a, release it, then press the listed key. Letter keys are lowercase unless Shift is shown.

| Shortcut | Action |
| --- | --- |
| Alt+1 through Alt+9 | Jump to that window, without the prefix. Numbers past the last window are ignored. |
| Alt+z | Toggle the current pane's zoom to fill the tmux window; press again to restore the layout. No prefix needed. |
| Alt+c | Create a window, without the prefix. |
| Alt+q | Close the current window and all its panes immediately, without the prefix. |
| Alt+v | Split vertically into left and right panes, without the prefix. |
| Alt+h | Split horizontally into top and bottom panes, without the prefix. |
| Alt+j / k / l | Focus the tmux pane down / up / right, without the prefix. Use Alt+Left to focus left. Neovim splits use their own navigation. |
| Alt+arrow key | Focus the tmux pane in that direction, without the prefix. |
| Prefix, z | Toggle pane zoom using tmux's standard shortcut. |
| Prefix, c | Create a window. |
| Prefix, n / p | Go to the next / previous window. |
| Prefix, w | Choose a window from the list. |
| Prefix, , | Rename the current window. |
| Prefix, % | Split into left and right panes. |
| Prefix, " | Split into top and bottom panes. |
| Prefix, arrow key | Focus the pane in that direction. |
| Prefix, o | Focus the next pane. |
| Prefix, x | Close the current pane after confirmation. |
| Prefix, [ | Enter copy mode to scroll through history; q exits. |
| Prefix, ] | Paste the tmux paste buffer. |
| Prefix, d | Detach from the session. Reattach with `tmux attach`. |
| Prefix, Ctrl+a | Send Ctrl+a to the application inside the pane. |
| Prefix, ? | List all tmux bindings; q exits. |

Mouse support is enabled: click to focus a pane, drag pane borders to resize, and scroll to browse history.

Windows number from 1 and renumber when one closes, so they always run 1 to n. On macOS, use the left Option key for Alt shortcuts: `modules/ghostty` configures it to act as Alt, while right Option still types special characters. Kitty sends Alt as is. Tmux handles these prefix-free Alt shortcuts before the application inside the pane.

## Appearance

Each pane has a full rounded outline. The entire focused outline uses the theme's accent colour; inactive outlines use its border colour. Neighbouring panes have two border columns or rows, so each outline belongs to one pane. Pane titles are hidden.

This requires the development tmux revision `9db7c8259d15f15575743427b8efb33c622aa9cf` (`next-3.9`), pinned in `default.nix`. The Catppuccin 2.1.3 patch removes its popup styling block because this tmux no longer accepts `popup-style` or `popup-border-style`. Revisit both overrides when a stable tmux release includes `pane-border-type` and Catppuccin supports it.

After `just switch`, new tmux servers use the pinned package. Existing servers keep their old binary. Finish their sessions before starting a new default server, or preview immediately with a separate server using `tmux -L outlined new-session`. Detaching and reattaching alone does not upgrade a running server.

Copy-mode and mouse selections use the theme's `selection` colour instead of Catppuccin's surface0 grey.

The `tmux` flake check loads the generated configuration in isolated servers and checks every outline's characters and colour through focus, zoom, and pane resizing. Run it with `nix build "path:$PWD#checks.aarch64-darwin.tmux"` (or the current system).
