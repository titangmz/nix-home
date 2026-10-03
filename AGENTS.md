# Working rules

- Read [STRUCTURE.md](STRUCTURE.md) before changing configuration.
- Keep `home.nix` small. Put packages, settings, and raw files in the owning module; personal identity belongs in `profiles/xray.nix`.
- Preserve the three system output names: `x86_64-linux`, `aarch64-darwin`, `x86_64-darwin`.
- Keep `home.stateVersion` at `25.11` unless intentionally migrating. Update dependency pins only as part of a requested dependency change.
- Manage packages and plugins through Nix; general CLI packages belong in `modules/cli/default.nix`. Use `yq-go` for Mike Farah's `yq` command. Add plugin mappings only when their dependencies are configured; avoid duplicate bindings and initialization.
- Keep Atuin in `modules/shell/default.nix` with Home Manager's Zsh integration. Initialize it only in Zsh, since Bash hands off to Zsh; preserve the Up binding and keep automatic sync disabled unless requested.
- Keep WezTerm configuration in `modules/wezterm` using `xdg.configFile`; the user installs WezTerm separately. Use built-in Catppuccin Mocha and bundled fonts, with subtle transparency and macOS blur; stable Linux builds rely on compositor blur settings. Preserve default shortcuts and application Ctrl keys, including Neovim's Ctrl-Space; custom pane shortcuts use Ctrl-Shift-a as leader.
- Keep tmux's pane terminal at `tmux-256color` and advertise RGB for WezTerm's outer `xterm-256color`/`wezterm` terminals in `modules/tmux/tmux.conf`, preserving other terminal features. The tmux prefix is Ctrl-a.
- Keep Blink completion mappings in `modules/neovim/editing.nix`: Insert-mode `Ctrl-e` accepts and `Ctrl-q` dismisses suggestions, with built-in fallback when completion is inactive.
- Neovim layouts belong in `modules/neovim/workspace`; preserve editor splits and running jobs when hiding panes. Keep AI CLI behavior in `modules/neovim/ai`, credentials outside Nix, and plugin actions beside their owning modules. Use the separate `nixpkgs-codex` input only for Codex; its 26.05 branch preserves Intel macOS support. Preserve the main dependency pins for editor changes.
- Neovim checks must include `programs.nixvim.build.extraFiles` in the runtime path as well as the generated init file. Test layout/process behavior with a fake AI CLI; authenticated AI and native platform support need separate runtime verification.
- Keep one shell per Neovim session, with the same native terminal buffer in both views to preserve colors/prompts. Block terminal-input mode in the bottom view; `Space tt` opens its focused floating input window and double Escape closes it. Cargo commands use that same shell. Keep Lazygit in a separate centered floating overlay.
- Validate configuration changes with `nix flake check "path:$PWD"`; evaluate other platforms with `--all-systems --no-build`. Evaluation alone does not prove native runtime support.
- Format Nix with `nix fmt` from the checkout. Unlike `nix flake check`, `nix fmt` passes positional arguments to the formatter. Keep documentation concise and consistent with the actual files and commands.
- Use flake checks for validation: `switch.sh` and `just switch` apply changes to the user's environment. Keep Just recipes as wrappers around `switch.sh`; `just benchmark-switch` times one real switch with Hyperfine.
- When structure, configuration, commands, or working rules change, update all affected Markdown files—including `STRUCTURE.md`, `README.md`, and `AGENTS.md`—in the same change.
