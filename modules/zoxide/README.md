# zoxide

[zoxide](https://github.com/ajeetdsouza/zoxide) provides `z` and `zi` in Zsh. It is initialized only in Zsh.

Where zoxide is enabled, the shell module drops the Oh My Zsh `z` plugin, so only one `z` tracks directories. Profiles without zoxide keep that plugin.

To carry over history from the old plugin, run `zoxide import --from z ~/.z` once.
