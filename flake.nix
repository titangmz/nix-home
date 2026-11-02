{
  description = "Home Manager profiles for Linux and macOS machines and a NixOS desktop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim/nixos-25.11";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixvim,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      # profiles/default.nix maps each switchable profile to its systems.
      profiles = import ./profiles;
      supportedSystems = lib.unique (lib.concatLists (lib.attrValues profiles));
      forAllSystems = lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
      mkHome =
        system: profile:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          modules = [
            profile
            nixvim.homeModules.nixvim
          ];
        };
    in
    {
      nixosModules.desktop = import ./modules/nixos/system;

      # One configuration per profile and supported system, named `<profile>-<system>`.
      homeConfigurations = lib.listToAttrs (
        lib.concatLists (
          lib.mapAttrsToList (
            name: systems:
            map (system: lib.nameValuePair "${name}-${system}" (mkHome system ./profiles/${name}.nix)) systems
          ) profiles
        )
      );

      apps = forAllSystems (system: {
        home-manager = {
          type = "app";
          meta.description = "Home Manager CLI from the locked input";
          program = "${home-manager.packages.${system}.home-manager}/bin/home-manager";
        };
      });

      checks = forAllSystems (
        system:
        import ./tests/checks.nix {
          inherit
            self
            lib
            system
            profiles
            ;
          pkgs = pkgsFor system;
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);
    };
}
