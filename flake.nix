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
      mkHome =
        system: profile:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          extraSpecialArgs.codexPackage = nixpkgs-codex.legacyPackages.${system}.codex;
          modules = [
            profile
            nixvim.homeModules.nixvim
          ];
        };
    in
    {
      nixosModules.desktop = import ./modules/nixos/system;

      homeConfigurations = (forAllSystems (system: mkHome system ./home.nix)) // {
        nixos-hyprland = mkHome "x86_64-linux" ./profiles/nixos-hyprland.nix;
      };

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
          home =
            assert !home.config.gtk.enable;
            assert home.config.xfconf.settings == { };
            assert home.config.programs.zed-editor.enable;
            assert nixpkgs.lib.hasInfix ".local/bin" home.config.programs.zsh.envExtra;
            assert nixpkgs.lib.all (path: !(builtins.hasAttr path home.config.xdg.configFile)) [
              "hypr/hyprland.lua"
              "waybar/config.jsonc"
              "waybar/style.css"
              "rofi/config.rasi"
              "mako/config"
            ];
            assert !(builtins.hasAttr "xfconfd" home.config.systemd.user.services);
            assert !(builtins.hasAttr "desktop-wallpaper" home.config.systemd.user.services);
            home.activationPackage;
          switch =
            pkgs.runCommand "switch-script-check"
              {
                nativeBuildInputs = [
                  pkgs.python3
                  pkgs.bash
                  pkgs.jq
                ];
              }
              ''
                SWITCH_SCRIPT=${./switch.sh} python ${./tests/test_switch.py}
                NIXOS_SWITCH_SCRIPT=${./switch-nixos.sh} python ${./tests/test_switch_nixos.py}
                REBUILD_SCRIPT=${./rebuild.sh} python ${./tests/test_rebuild.py}
                BOOTSTRAP_SCRIPT=${./bootstrap-nixos.sh} python ${./tests/test_bootstrap_nixos.py}
                SETUP_MONITORS_SCRIPT=${./setup-monitors.sh} python ${./tests/test_setup_monitors.py}
                SCRIPTS_DIR=${./scripts} python -m unittest discover \
                  --start-directory ${./tests/scripts} \
                  --pattern 'test_*.py'
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
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          nixos-hyprland =
            let
              desktop = self.homeConfigurations.nixos-hyprland;
            in
            assert builtins.hasAttr "rofi/config.rasi" desktop.config.xdg.configFile;
            assert desktop.config.home.pointerCursor.name == "Bibata-Modern-Classic";
            assert desktop.config.gtk.cursorTheme.name == "Bibata-Modern-Classic";
            assert nixpkgs.lib.hasInfix "no_hardware_cursors = true"
              desktop.config.xdg.configFile."hypr/hyprland.lua".text;
            assert nixpkgs.lib.hasInfix "hl.plugin.load(\"/etc/hyprland-plugins/libhyprbars.so\")"
              desktop.config.xdg.configFile."hypr/hyprland.lua".text;
            assert nixpkgs.lib.hasInfix "hyprbars" desktop.config.xdg.configFile."hypr/hyprland.lua".text;
            desktop.activationPackage;

          nixos-module =
            let
              moduleConfig = self.nixosModules.desktop {
                inherit pkgs;
                lib = nixpkgs.lib;
              };
              features = moduleConfig.nix.settings.experimental-features.content;
            in
            assert builtins.elem "nix-command" features;
            assert builtins.elem "flakes" features;
            assert moduleConfig.programs.nix-ld.enable;
            assert moduleConfig.services.greetd.enable;
            assert moduleConfig.services.greetd.useTextGreeter;
            assert nixpkgs.lib.hasInfix "start-hyprland"
              moduleConfig.services.greetd.settings.default_session.command;
            assert
              moduleConfig.environment.etc."hyprland-plugins/libhyprbars.so".source
              == "${pkgs.hyprlandPlugins.hyprbars}/lib/libhyprbars.so";
            assert moduleConfig.programs.dconf.enable;
            pkgs.runCommand "nixos-module-check" { } ''
              touch "$out"
            '';

        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);
    };
}
