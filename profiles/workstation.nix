# Layer: everything a personal machine has beyond the server core.
{
  imports = [
    ./base.nix
    ../modules/neovim/ai
    ../modules/neovim/development
    ../modules/development
    ../modules/chat
    ../modules/v2rayn
    ../modules/proxychains
    ../modules/zoxide
  ];
}
