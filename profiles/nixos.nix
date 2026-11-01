# Profile: the NixOS Hyprland desktop. Pair it with `nixosModules.desktop`.
{
  imports = [
    ./workstation.nix
    ../modules/nixos/desktop
  ];
}
