# nix-home

Personal Home Manager configuration for `xray`, with pinned Nixpkgs, Home Manager,
and Nixvim. A separate locked Nixpkgs 26.05 input supplies Codex only. Supports x86_64
Linux, Apple Silicon macOS, and Intel macOS.

The existing platform outputs contain the shared Home Manager setup. The NixOS
Hyprland desktop is an explicit, separate `nixos-hyprland` profile; default
switches on Linux and macOS do not include it.
Reusable NixOS additions live in `modules/nixos/system`. Each machine keeps its
base configuration, hardware settings, and NixOS package source outside this repo.
Kitty's configuration is managed by Home Manager in `modules/kitty`; the Kitty
package itself remains system-managed on NixOS.

## Setup and use

Install Nix using the daemon installer (run in Bash or Zsh):

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Open a new terminal, then enable flakes by adding this to
`~/.config/nix/nix.conf` (or `/etc/nix/nix.conf`):

```ini
experimental-features = nix-command flakes
```

Review `profiles/xray.nix` for username and Git identity. Home directories default
to `/home/xray` on Linux and `/Users/xray` on macOS. From the checkout:

```bash
./switch.sh --dry-run    # Preview
./switch.sh              # Apply
```

The script works from any directory, forwards Home Manager options, and uses the
locked CLI; no separate Home Manager installation is needed.

After the first switch installs `just` and `hyperfine`, use:

```bash
just switch --dry-run   # Preview
just switch             # Apply
just benchmark-switch   # Time one real switch with Hyperfine
```

The benchmark runs `hyperfine --runs 10 --show-output 'just switch'`, applies the
configuration ten times, and prints the elapsed time. Cached builds make later
switches faster. Run `just` to list recipes.

## Essential details

- Machine-local shell overrides go in `~/.config/zsh/local.zsh` (optional).
- Interactive Bash hands off to Zsh. Pyenv uses `~/.pyenv`; tmux plugins need no TPM.
- Atuin records local shell history: `Ctrl-r` opens search, while Up keeps normal Zsh behavior. After applying, open a new terminal and run `atuin import zsh` once to import existing history. Automatic sync and update checks are disabled; Nix manages the version.
- Docker aliases require Docker; terminal icons require a Nerd Font.
- CLI tools include `jq` for JSON, Mike Farah's `yq` (`yq-go` in Nixpkgs) for YAML/TOML, `just` for project commands, `hyperfine` for benchmarking, and `watchexec` for rerunning commands on file changes.
- Run `nix flake check "path:$PWD"` for configuration changes and `nix fmt` from the checkout to format Nix. Native macOS builds remain unverified.

See [STRUCTURE.md](STRUCTURE.md) for the layout and [AGENTS.md](AGENTS.md) for
contributor rules.

## NixOS Hyprland desktop (opt in)

This profile is for selected x86_64 NixOS machines. Apply it explicitly:

```bash
./switch.sh --profile nixos-hyprland --dry-run
./switch.sh --profile nixos-hyprland
# Equivalent wrapper:
just switch-nixos
```

`profiles/nixos-hyprland.nix` extends the portable `home.nix` with
`modules/nixos/desktop`. Other machines continue using `./switch.sh` or
`just switch`, with their original platform output. Platform detection never
selects the desktop automatically. A default switch on a machine previously
using the desktop profile removes its Home Manager-managed desktop files and
services, so continue using the explicit profile on those machines.
The shared NixOS additions are described below; hardware settings stay local.

`modules/nixos/desktop` manages the Catppuccin Mocha GTK theme with mauve accents,
matching Papirus-Dark folder icons, and Noto Sans. It also sets Thunar's icon
view, shortcuts sidebar, breadcrumbs, and folders-first sorting. Apply the
desktop profile, then close and reopen Thunar to load the GTK theme. These
settings also theme other GTK applications on opted-in machines.

Hyprland's Lua config lives in `modules/nixos/desktop/hyprland`, Waybar's config and CSS
in `modules/nixos/desktop/waybar`, and Mako's notification theme in `modules/nixos/desktop/mako`.
Edit `modules/nixos/desktop/palette.nix` to change shared colors, GTK flavor, or GTK
accent. The Lua/CSS/Mako sources use `@color@` placeholders rendered by Nix.
Focused windows use an opaque mauve/blue gradient, with subdued inactive borders.
Home Manager installs the files under `~/.config` and manages Waybar/Mako
packages; NixOS still supplies Hyprland and its portals. Apply the desktop profile,
then run `hyprctl reload config-only` and `makoctl reload`; restart Waybar if its
styling changed. Hyprland's startup commands launch Waybar and Mako, with no
duplicate Home Manager services. When first adopting existing local files,
`./switch.sh --profile nixos-hyprland -b desktop-migration` preserves backups
before creating managed links.

The default wallpaper is `modules/nixos/desktop/wallpaper/wallpaper.png`.
Hyprland starts the `desktop-wallpaper` user service at login. For a local
replacement, put a PNG (or a symlink to one) at
`~/.local/share/wallpapers/override.png`, then run:

```sh
systemctl --user restart desktop-wallpaper.service
```

The equivalent Just command is `just wallpaper`.

Remove the override and restart the service to return to the bundled wallpaper.
Override selection happens at runtime, without a Nix rebuild. The default is
also available at `~/.local/share/wallpapers/wallpaper.png`.

## NixOS system configuration

### Clean NixOS installation

After installing NixOS, let NixOS keep its generated machine files locally:

```bash
sudo nixos-generate-config
```

Clone this repository somewhere stable, for example `/home/xray/nix-home`:

```bash
git clone <repository-url> /home/xray/nix-home
```

Edit `/etc/nixos/configuration.nix` and add the shared module alongside the
generated hardware file:

```nix
imports = [
  ./hardware-configuration.nix
  /home/xray/nix-home/modules/nixos/system
];
```

Keep the hardware file and machine-specific settings in `/etc/nixos`. Do not
copy them into this repository. Keep the checkout at the imported path, or
change the absolute path in the import.

Apply the operating-system configuration first:

```bash
sudo nixos-rebuild switch
```

Then apply the shared Home Manager configuration and the Hyprland desktop:

```bash
/home/xray/nix-home/switch.sh --profile nixos-hyprland
```

After that, use `just switch-system` for NixOS changes, `just switch-nixos` for
Hyprland and other Linux desktop changes, and `just switch` for portable
Home Manager changes.

Only our shared additions live in `modules/nixos/system/default.nix`: Hyprland,
audio, portals, Nerd Fonts, desktop applications, and the CLI tools (`git`,
`curl`, `vim`, and `wget`). The flake also exports this
module as `nixosModules.desktop`. There are no machine registrations or hardware
files in this repo. Adding or removing a machine requires no repository change.

On each opted-in NixOS machine, add the module to its local
`/etc/nixos/configuration.nix` (adjust the checkout path):

```nix
imports = [
  ./hardware-configuration.nix
  /home/xray/nix-home/modules/nixos/system
];
```

Move any duplicate desktop settings or packages into the shared module. Keep the
machine's bootloader, filesystems, hostname, users, locale, networking, and
`system.stateVersion` in its local configuration. The checkout must remain
available at the imported path. System rebuilds use each machine's own NixOS
package source/channel; ensure its Hyprland supports our Lua configuration.
The shared Home Manager dependency pins remain unchanged.

```bash
just build-system       # Build the local OS without applying it
just switch-system      # Apply the local OS with sudo
just switch-nixos       # Apply shared Home Manager settings plus the desktop
```

The system recipes wrap `rebuild.sh`, which selects
`/etc/nixos/configuration.nix`; there is no host argument or repo system flake.
Home Manager remains standalone and uses `switch.sh`. System rebuilds do not
switch the home configuration. Flake checks cover the Home Manager profiles
and scripts; `just build-system` validates the complete local NixOS system.

## WezTerm

Install WezTerm yourself, then apply with `./switch.sh`. Home Manager manages
`~/.config/wezterm/wezterm.lua`; edit its source in `modules/wezterm/wezterm.lua`.
The configuration uses built-in Catppuccin Mocha, bundled JetBrains Mono with
Nerd Font/emoji fallback, 13-point text, padding, 10,000 lines of scrollback,
quiet bells, 90% background opacity, and a tab bar that hides when only one tab
is open. macOS uses a blur radius of 16; Linux blur depends on compositor
settings with stable WezTerm. New shells use
Nix-managed Zsh, including when launched from the macOS Dock.

Press **Ctrl-Shift-a**, release, then press a key within one second:

| Key after leader | Action |
| --- | --- |
| `v` / `s` | Split side by side / top and bottom |
| `h/j/k/l` | Focus left / down / up / right pane |
| `z` / `x` | Toggle pane zoom / close pane with confirmation |
| `r`, then `h/j/k/l` | Resize pane; Enter/Escape exits, or wait three seconds |
| `t` / `n` / `p` / `w` | New tab / next tab / previous tab / tab navigator |
| `y` / `f` / `Space` | Copy mode / search scrollback / Quick Select |

Default shortcuts remain available: Ctrl-Shift-C/V copies/pastes, Ctrl-Shift-P
opens the command palette, and Ctrl-Shift-R reloads configuration. On macOS,
Cmd-C/V and Cmd-plus/minus work too. Ctrl-Space still reaches Neovim completion;
tmux's Ctrl-a prefix is preserved. WezTerm normally reloads config changes
automatically. Validate the generated Lua with your installed WezTerm:

```bash
wezterm --config-file ~/.config/wezterm/wezterm.lua show-keys --lua
```

Tmux uses `tmux-256color` inside panes and advertises RGB support for WezTerm's
outer `xterm-256color`/`wezterm` terminals, preserving Neovim's Catppuccin colors.
After applying, update an existing tmux server without stopping its jobs:

```sh
tmux source-file ~/.config/tmux/tmux.conf
```

Detach with Ctrl-a then `d` and reattach with `tmux attach` to refresh the
client's terminal capabilities. `tmux list-clients -F '#{client_termfeatures}'`
should include `RGB`.

## Neovim workspace

Neovim starts in **Code**: a Neo-tree sidebar and the editor. Solid Catppuccin
Mocha, a compact buffer bar, and Which-key provide a consistent interface.
Press Space and pause to discover the shortcuts, or `Space fk` to search them.

| Keys | Action |
| --- | --- |
| `Space z` | Toggle editor-only Focus and restore the previous arrangement |
| `Space l1` / `l2` / `l3` / `l4` | Focus / Code / Git Review / Full |
| `Space ll` / `Space lr` | Choose a layout / return from Focus or Review |
| `Space e` / `Space E` | Toggle file tree / reveal the current file |
| `Space ff` / `fg` / `fb` | Find files / search text / find buffers |
| `Space fF` / `Space fG` | Include hidden and ignored files / text |
| `Space tt` / `Space to` | Toggle focused shell popup / read-only bottom output |
| `Space aa` / `af` / `ap` | Toggle Codex / insert file context / choose prompt |
| Visual `Space av` | Insert selected code into Codex |
| `Space gg` / `gd` / `gh` | Lazygit / review changes / file history |
| `Space gp` / `gs` / `gu` / `gR` | Preview / stage / undo stage / reset hunk |
| `Space gb` / `[h` / `]h` | Toggle line blame / previous / next hunk |
| `Space ca` / `cr` / `cf` / `ct` | Code action / rename / format / toggle format on save |
| `Space cd` / `Space xx` | Line diagnostics / workspace diagnostics |
| `gd` / `gr` / `K` / `[d` / `]d` | Definition / references / hover / diagnostic navigation |
| `Space rr` / `rc` / `rt` | Cargo run / check / test |
| `Space wv` / `ws` / `wc` / `w=` | Vertical split / horizontal split / close / equalize |
| `Space w>` / `w<` / `w+` / `w-` | Increase / decrease pane width or height |
| `Space bn` / `bd` / `bs` | New buffer / close buffer / save |
| `Tab` / `Shift-Tab` | Next / previous buffer in editor windows |
| `Ctrl-h/j/k/l` | Move between panes, including terminal mode |
| Insert `Ctrl-e` / `Ctrl-q` | Accept / dismiss completion suggestions |
| Double Escape | Close the shell popup; normal mode in AI/Lazygit |

Completion uses Blink: `Ctrl-n` / `Ctrl-p` choose suggestions and `Ctrl-Space`
opens the menu. `Ctrl-e` accepts the selected suggestion (or the first if none
is selected); `Ctrl-q` cancels. Both retain built-in behavior when completion
is inactive. `Ctrl-y` also remains available to accept suggestions.

Full shows tree, editor, Codex on the right, and read-only shell output below.
On narrow screens the tree hides first; Codex and shell output share the bottom slot.
`Space to` selects shell output in the bottom slot; `Space aa` selects Codex.
Widening the screen restores requested panes. Focus preserves splits, unsaved
buffers, cursor positions, and jobs;
hiding tools keeps processes alive within the Neovim session. Review uses a
separate Diffview tab; `Space lr` returns to the editor. Lazygit opens in a centered
floating window with a rounded border; `q` closes it and returns to the editor.
Tool pane sizes are remembered when switching layouts within the session.

There is one persistent shell for the whole Neovim session. `Space tt` opens it
in a centered popup with keyboard focus and immediate input; double Escape
closes the popup without stopping the shell. Both views display the same native
terminal buffer, preserving prompt formatting and ANSI colors. The bottom pane
supports scrolling/copying and blocks terminal input; typing is available only
in the popup. `Space to` shows/hides the output pane independently. The shell
starts at the first workspace root and retains its working directory across
tabs; use `cd` in the popup to change it. Cargo shortcuts run in this shell at
the current workspace root without changing its working directory.

`:WorkspaceLayout [focus|code|review|full]` and `:WorkspaceRestore` are the command
equivalents. Each workspace tab fixes its root at the Git root (or the opened
directory outside Git), shared by the tree, search, tasks, and AI.
Layouts and the shell process are not restored across editor restarts.

After applying, run `codex login` once and complete ChatGPT sign-in. Credentials
remain in Codex's own local storage, outside Nix. Context shortcuts insert text
into the Codex prompt for review; submit it with Enter. Existing unsaved editor
changes are preserved when Codex modifies files on disk. AI is CLI-only; it does
not require Copilot or an additional API subscription.

Rust uses rust-analyzer, Clippy, and rustfmt; Nix uses nixd and nixfmt. Shell,
JSON, YAML, and TOML have language servers; shell, config files, and Markdown
have Nix-managed formatters. Formatting runs on save and respects formatter
configuration; `Space ct` toggles it. Cargo tasks keep their output and reject a
second task while one is running; open the shell popup and press Ctrl-C to stop it.

The flake's Neovim check exercises layout restoration, the single shell and
native read-only terminal view, popup closing, narrow screens, Git review, context
delivery through a fake AI CLI, and real Rust/Nix formatting. Authenticated AI
use and native macOS runtime behavior require
separate interactive verification.
