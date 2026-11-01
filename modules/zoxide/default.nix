{
  programs.zoxide = {
    enable = true;
    # Interactive Bash hands off to Zsh, which initializes zoxide once.
    enableBashIntegration = false;
  };
}
