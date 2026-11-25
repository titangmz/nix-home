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
    gum
    hyperfine
    watchexec
    tldr
    procs
    gping
    mtr
    dig
    unzip
    btop
    ctop
    sshuttle
    dysk
    netcat
    pass
  ];

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  xdg.configFile."eza/theme.yml".source = ./eza-theme.yml;
}
