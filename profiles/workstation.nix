# Layer: everything a personal machine has beyond the server core.
{
  imports = [
    ./base.nix
    ../modules/ghostty
    ../modules/cli/extras
    ../modules/neovim/development
    ../modules/development
    ../modules/chat
    ../modules/nb
    ../modules/v2rayn
    ../modules/proxychains
  ];
}
