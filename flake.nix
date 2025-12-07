{
  description = "Home Manager flake for xray";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim/nixos-25.11";
  };

  outputs = { self, nixpkgs, home-manager, nixvim, ... }:
  let
    lib = nixpkgs.lib;
    # Support both Mac and Linux
    supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
    
    # Create home configuration for a given system
    mkHomeConfig = system:
      let
        pkgs = import nixpkgs { inherit system; };
        # Get username from environment (works in impure evaluation)
        # Fallback to "xray" if USER env var is not set
        envUser = builtins.getEnv "USER";
        username = if envUser == "" then "xray" else envUser;
        # Construct home directory based on OS
        homeDir = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
      in
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit username homeDir;
        };
        modules = [
          ./home.nix
          nixvim.homeModules.nixvim
        ];
      };
  in
  {
    # Default "xray" configuration for each system
    # Use: home-manager switch --flake .#xray
    # Home Manager will automatically use the correct system's packages
    homeConfigurations = lib.genAttrs supportedSystems (system: mkHomeConfig system);
  };
}

