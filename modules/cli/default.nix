{ pkgs, ... }:
{
  home.packages = with pkgs; [
    curl
    vim
    wget
    unar
    bat
    tree
    caddy
    eza
    duf
    dust
    fd
    ripgrep
    fzf
    jq
    yq-go
    just
    hyperfine
    watchexec
    tldr
    procs
    gping
    mtr
    btop
    ctop
    sshuttle
    dysk
    netcat
    pass
    gnupg
  ];

  xdg.configFile."eza/theme.yml".source = ./eza-theme.yml;
}
