# Repository structure

```text
flake.nix              Inputs (including Codex-only pin), systems, app, checks, formatter
flake.lock             Pinned dependency revisions
home.nix               Portable module imports and Home Manager state version
profiles/xray.nix      Username, home directory, Git identity
profiles/nixos-hyprland.nix  Explicit NixOS desktop profile, extending home.nix
modules/
  cli/                 General CLI packages and Eza theme
  shell/               Zsh, Bash handoff, Atuin history, Starship, session paths
  git/                 Git and Lazygit settings
  tmux/                Managed plugins and terminal settings
  wezterm/             Configuration only; externally installed WezTerm
  kitty/               Kitty configuration; package remains system-managed
  development/         Rust tools, fnm, pyenv
  chat/                Profanity package and configuration
  nixos/
    system/            Reusable NixOS additions, including desktop and CLI packages; imported by local /etc/nixos
    desktop/           Explicit desktop modules, excluded from portable home.nix
      palette.nix      Shared Catppuccin colors, GTK flavor/accent, template renderer
      hyprland/        Lua configuration; NixOS owns compositor and portals
      waybar/          Bar configuration, CSS, packages, and button dependencies
      mako/            Notification styling, daemon package, and notify-send
      wallpaper/       Bundled wallpaper.png, runtime override, Hyprpaper service
  neovim/              Editing/formatting, languages/LSP, navigation, UI, Git, keymaps
    workspace/         Layout controller, single shell with two views, Cargo tasks
    ai/                CLI-only Sidekick/Codex integration and context actions
switch.sh              Portable default; explicit --profile for the NixOS desktop
rebuild.sh             Local /etc/nixos build/switch wrapper; build is the default
justfile               Home/system wrappers, wallpaper restart, and Hyperfine benchmark
tests/                 Home/system script tests and Neovim behavioral checks
```

Each module owns its packages, settings, and raw configuration files. Keep
plugin-specific Neovim mappings beside the plugin configuration; built-in
mappings belong in `modules/neovim/keymaps.nix`. Add top-level modules to
`home.nix` only for shared configuration; keep personal settings in the profile.
The `x86_64-linux`, `aarch64-darwin`, and `x86_64-darwin` outputs retain the
portable home configuration. `nixos-hyprland` is a separate x86_64 Linux output,
composed by `profiles/nixos-hyprland.nix`. Desktop modules are never imported by
the portable outputs, including on Linux. Use `./switch.sh --profile nixos-hyprland`
or `just switch-nixos` only on machines that should receive this desktop.
`modules/nixos/system` owns shared NixOS additions, including desktop and CLI
packages, and is exported as
`nixosModules.desktop`. Each machine's `/etc/nixos/configuration.nix` imports
it alongside its local hardware file. Boot settings, filesystem UUIDs, users,
hostname, locale, networking, `system.stateVersion`, and the NixOS package
source remain local. There are no host directories or `nixosConfigurations`
outputs in this repo. The portable Home Manager and Codex pins are unchanged.
System and home activation stay separate: `just build-system` builds the local
OS, `just switch-system` applies it with sudo, and `just switch-nixos` applies
the complete shared home plus desktop. Adding/removing machines needs no Git
change. Flake checks cover home profiles/scripts; full system validation uses
`just build-system` on the target machine.
`modules/neovim/editing.nix` owns Blink completion and its Insert-mode mappings:
`Ctrl-e` accepts suggestions and `Ctrl-q` dismisses them.

`modules/nixos/desktop` configures Linux GTK applications with Catppuccin Mocha,
mauve accents, Papirus-Dark icons with matching folders, and Noto Sans. Thunar
uses an icon view, shortcuts sidebar, breadcrumbs, and folders-first sorting.
The module provides user-session D-Bus activation for Xfconf on Hyprland;
only the explicit desktop profile enables it.
Its `hyprland`, `waybar`, and `mako` submodules own the compositor, bar, and
notification configuration files. Home Manager installs them at `~/.config/hypr`,
`~/.config/waybar`, and `~/.config/mako`. NixOS owns the Lua-compatible Hyprland
package and portals; Home Manager owns Waybar/Mako packages. Hyprland startup
commands launch both, without duplicate systemd services. `palette.nix` provides
shared hex colors and GTK flavor/accent. Lua, CSS, and Mako sources use `@color@`
placeholders rendered during evaluation; Mako also replaces `@HOME@` with the
profile's home directory. Focused windows use an opaque mauve/blue border gradient.

`modules/nixos/desktop/wallpaper` owns `wallpaper.png` and the
`desktop-wallpaper` user service. Its launcher selects a readable
`~/.local/share/wallpapers/override.png` at runtime, falling back to the bundled
image in the Nix store. The default is also installed under
`~/.local/share/wallpapers/wallpaper.png`. Hyprland imports its current
Wayland environment and starts the service at login. Restart the service to
pick up an added, replaced, or removed override; no rebuild is required.

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
