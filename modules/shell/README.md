# Shell

Zsh, the Bash handoff to Zsh, Atuin, and the Roundy prompt. Prompt colors come from `modules/theme`. The right side of the prompt shows `user@host`, so SSH sessions are easy to tell apart.

Directory jumping is zoxide, from `modules/zoxide`.

Direnv and nix-direnv are enabled in every profile through base, with Zsh integration.
To load a project's `flake.nix` development shell when entering its directory,
add `use flake` to the project's `.envrc`, then run `direnv allow` there once.
Direnv unloads the environment when leaving the directory; nix-direnv caches it
for faster reloads. Changes to `.envrc` require another `direnv allow`.

Atuin is initialized only in Zsh. Up keeps normal history. Automatic sync is off.

When running in a local Kitty window, `ssh` uses Kitty's SSH kitten when available. It
makes the `xterm-kitty` terminfo available remotely, so interactive programs
work without changing `TERM` or installing Kitty on each server. Other
terminals, SSH sessions (including nested SSH), and portable hosts continue to
use OpenSSH directly. The wrapper checks the Kitty window ID and SSH session
variables because `TERM=xterm-kitty` also survives on remote machines.

Machine-local shell settings go in `~/.config/zsh/local.zsh`.
