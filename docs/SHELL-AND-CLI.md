# Shell and CLI

Apply these settings with `just switch` on a portable Home Manager machine or
`just switch-nixos` on the NixOS desktop.

- Optional machine-local Zsh overrides belong in
  `~/.config/zsh/local.zsh`.
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
