# Shell and CLI

Apply these settings with `just switch` on a portable Home Manager machine or
`just switch-nixos` on the NixOS desktop.

- Optional machine-local Zsh overrides belong in
  `~/.config/zsh/local.zsh`.
- Roundy is pinned from GitHub and themed with the shared Catppuccin Mocha
  palette. Its `R_MODE`, `R_CODE`, `R_MIN`, `R_USR`, and `RT[...]` settings can
  be overridden in `~/.config/zsh/local.zsh`.
- Interactive Bash hands off to Zsh.
- Pyenv uses `~/.pyenv`.
- Tmux plugins are Nix-managed and do not require TPM.
- Docker aliases require Docker.
- Terminal icons require a Nerd Font.

Atuin is initialized only in Zsh. `Ctrl-r` opens local history search and Up
retains normal Zsh behavior. Automatic sync and update checks are disabled.
After first applying the configuration, import existing history once:

```bash
atuin import zsh
```

General CLI tools include `jq`, Mike Farah's `yq` (`yq-go` in Nixpkgs), `just`,
`hyperfine`, and `watchexec`.

## Personal scripts

Put portable executable scripts directly in the repository's `scripts/`
directory and mark them executable, for example:

```bash
chmod +x scripts/my-command
just switch
```

On the NixOS desktop, use `just switch-nixos` instead. Home Manager deploys
each non-hidden top-level file into `~/.local/bin`, which is included in the
session `PATH` and enforced at Zsh startup even if the user manager retained
stale Home Manager session variables, so the filename becomes the command name.
Commit scripts that should be
available on other machines. Keep platform-specific behavior guarded inside
the script when it is not shared by Linux and macOS.
