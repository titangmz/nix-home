# Shell

Zsh, the Bash handoff to Zsh, Atuin, and the Roundy prompt. Prompt colors come from `modules/theme`. The right side of the prompt shows `user@host`, so SSH sessions are easy to tell apart.

Directory jumping is zoxide, from `modules/zoxide`.

Atuin is initialized only in Zsh. Up keeps normal history. Automatic sync is off.

When running inside Kitty, `ssh` uses Kitty's SSH kitten when available. It
makes the `xterm-kitty` terminfo available remotely, so interactive programs
work without changing `TERM` or installing Kitty on each server. Other
terminals and portable hosts continue to use OpenSSH directly.

Machine-local shell settings go in `~/.config/zsh/local.zsh`.
