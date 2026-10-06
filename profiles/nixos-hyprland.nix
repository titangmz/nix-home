{ pkgs, ... }:
{
  imports = [
    ../home.nix
    ../modules/nixos/desktop
  ];

  assertions = [
    {
      assertion = pkgs.stdenv.isLinux;
      message = "The nixos-hyprland Home Manager profile requires Linux.";
    }
  ];
}
