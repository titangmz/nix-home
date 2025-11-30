{
  description = "Home Manager flake for xray";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    lib = nixpkgs.lib;
  in
  {
    homeConfigurations = {
	xray = home-manager.lib.homeManagerConfiguration {
		inherit pkgs;
		modules = [ ./home.nix ];
	};
    };
  };
}

