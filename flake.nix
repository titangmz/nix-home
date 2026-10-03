{
  description = "Home Manager configuration for xray's Linux and macOS machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim/nixos-25.11";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    # Only Codex comes from this input; the editor and home keep their existing pins.
    # The maintained 26.05 branch still supports Intel macOS.
    nixpkgs-codex.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixvim,
      nixpkgs-codex,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      homeConfigurations = forAllSystems (
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          extraSpecialArgs.codexPackage = nixpkgs-codex.legacyPackages.${system}.codex;
          modules = [
            ./home.nix
            nixvim.homeModules.nixvim
          ];
        }
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
        let
          pkgs = pkgsFor system;
          home = self.homeConfigurations.${system};
          editor = home.config.programs.nixvim;
          mappingKeys = map (mapping: "${mapping.mode}:${mapping.key}") editor.keymaps;
        in
        {
          home = home.activationPackage;
          switch =
            pkgs.runCommand "switch-script-check"
              {
                nativeBuildInputs = [
                  pkgs.python3
                  pkgs.bash
                ];
              }
              ''
                SWITCH_SCRIPT=${./switch.sh} python ${./tests/test_switch.py}
                touch "$out"
              '';
          neovim =
            assert builtins.length mappingKeys == builtins.length (nixpkgs.lib.unique mappingKeys);
            pkgs.runCommand "neovim-smoke-check" { } ''
              export XDG_CONFIG_HOME="$TMPDIR/config"
              export XDG_CACHE_HOME="$TMPDIR/cache"
              export XDG_DATA_HOME="$TMPDIR/data"
              export XDG_STATE_HOME="$TMPDIR/state"
              mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"
              ${editor.build.package}/bin/nvim --headless -i NONE --cmd "set runtimepath^=${editor.build.extraFiles}" -u ${editor.build.initFile} -c "luafile ${./tests/neovim.lua}"
              touch "$out"
            '';
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);
    };
}
