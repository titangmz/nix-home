# CLI

General command-line packages, including `curl`, `vim`, `wget`, `mtr`, `jq`, `yq-go` (`yq`), `just`, `hyperfine`, and `watchexec`. The Eza theme is `eza-theme.yml`.

`pass` uses Home Manager's GPG configuration and agent in every profile. The agent uses `pinentry-curses` for passphrase prompts in local terminals and over SSH; Bash and Zsh integration set `GPG_TTY` to the current terminal. Home Manager manages `~/.gnupg/gpg-agent.conf`; imported keys and the password store remain local data.

After applying this configuration, open a new terminal or run `exec zsh`. If an already running agent still reports `No pinentry`, run `gpgconf --reload gpg-agent`, then retry `pass show <entry>`. A `No secret key` error instead requires importing the matching secret key, including its encryption subkey; importing only the public key permits inserts but cannot decrypt entries. List secret keys with `gpg --list-secret-keys --keyid-format long`.

`extras` adds cowsay, lolcat, rustscan, tor, and torsocks. Only `profiles/workstation.nix` imports it, so servers stay lean.
