{ pkgs, ... }:
{
  home.packages = with pkgs; [
    unar
    cowsay
    lolcat
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
    btop
    ctop
    sshuttle
    rustscan
    dysk
    netcat
    pass
    gnupg
    tor
    torsocks
  ];

  xdg.configFile."eza/theme.yml".source = ./eza-theme.yml;
}
