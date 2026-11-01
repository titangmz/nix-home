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
      lib = nixpkgs.lib;
      # profiles/default.nix maps each switchable profile to its systems.
      profiles = import ./profiles;
      supportedSystems = lib.unique (lib.concatLists (lib.attrValues profiles));
      forAllSystems = lib.genAttrs supportedSystems;
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
        let
          pkgs = pkgsFor system;
          supports = name: builtins.elem system profiles.${name};
          homeFor = name: self.homeConfigurations."${name}-${system}";
          hasPackage = home: pname: lib.any (pkg: (pkg.pname or "") == pname) home.config.home.packages;
          desktopFiles = [
            "hypr/hyprland.lua"
            "kitty/kitty.conf"
            "waybar/config.jsonc"
            "waybar/style.css"
            "rofi/config.rasi"
            "mako/config"
          ];
          writesNoDesktopFiles =
            home: lib.all (path: !(builtins.hasAttr path home.config.xdg.configFile)) desktopFiles;
          neovimCheck =
            name: home: script:
            let
              editor = home.config.programs.nixvim;
            in
            pkgs.runCommand name { } ''
              export XDG_CONFIG_HOME="$TMPDIR/config"
              export XDG_CACHE_HOME="$TMPDIR/cache"
              export XDG_DATA_HOME="$TMPDIR/data"
              export XDG_STATE_HOME="$TMPDIR/state"
              mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"
              ${editor.build.package}/bin/nvim --headless -i NONE --cmd "set runtimepath^=${editor.build.extraFiles}" -u ${editor.build.initFile} -c "luafile ${script}"
              touch "$out"
            '';
          server = homeFor "server";
          workstationName = if pkgs.stdenv.isDarwin then "mac" else "pc";
        in
        {
          server =
            assert !server.config.gtk.enable;
            assert writesNoDesktopFiles server;
            assert lib.hasInfix ".local/bin" server.config.programs.zsh.envExtra;
            assert lib.hasInfix "command kitten ssh" server.config.programs.zsh.initContent;
            assert server.config.programs.nixvim.enable;
            assert lib.all (pname: !(hasPackage server pname)) [
              "codex"
              "cargo"
              "fnm"
              "profanity"
              "v2rayn"
              "proxychains-ng"
            ];
            assert !(builtins.hasAttr ".proxychains/proxychains.conf" server.config.home.file);
            server.activationPackage;
          server-neovim = neovimCheck "server-neovim-smoke-check" server ./tests/neovim-server.lua;
          switch =
            let
              # These scripts drive NixOS and Hyprland, which run only on Linux.
              linuxScriptTests = lib.optionalString pkgs.stdenv.isLinux ''
                NIXOS_SWITCH_SCRIPT=${./switch-nixos.sh} python ${./tests/test_switch_nixos.py}
                REBUILD_SCRIPT=${./rebuild.sh} python ${./tests/test_rebuild.py}
                BOOTSTRAP_SCRIPT=${./bootstrap-nixos.sh} python ${./tests/test_bootstrap_nixos.py}
                SETUP_MONITORS_SCRIPT=${./setup-monitors.sh} python ${./tests/test_setup_monitors.py}
              '';
            in
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
                BOOTSTRAP_HOME_SCRIPT=${./bootstrap-home.sh} python ${./tests/test_bootstrap_home.py}
                ${linuxScriptTests}
                SCRIPTS_DIR=${./scripts} python -m unittest discover \
                  --start-directory ${./tests/scripts} \
                  --pattern 'test_*.py'
                touch "$out"
              '';
        }
        // lib.optionalAttrs (supports workstationName) (
          let
            workstation = homeFor workstationName;
            editor = workstation.config.programs.nixvim;
            mappingKeys = map (mapping: "${mapping.mode}:${mapping.key}") editor.keymaps;
          in
          {
            # pc on Linux, mac on macOS: both are the workstation layer plus at most one module.
            workstation =
              assert !workstation.config.gtk.enable;
              assert workstation.config.xfconf.settings == { };
              assert writesNoDesktopFiles workstation;
              assert !(builtins.hasAttr "xfconfd" workstation.config.systemd.user.services);
              assert !(builtins.hasAttr "desktop-wallpaper" workstation.config.systemd.user.services);
              assert hasPackage workstation "codex";
              assert hasPackage workstation "v2rayn";
              assert hasPackage workstation "proxychains-ng";
              assert lib.hasInfix "socks5 127.0.0.1 10808" (
                builtins.readFile workstation.config.home.file.".proxychains/proxychains.conf".source
              );
              assert
                pkgs.stdenv.isDarwin
                == builtins.hasAttr "Library/Application Support/com.mitchellh.ghostty/config" workstation.config.home.file;
              workstation.activationPackage;
            neovim =
              assert builtins.length mappingKeys == builtins.length (lib.unique mappingKeys);
              neovimCheck "neovim-smoke-check" workstation ./tests/neovim.lua;
          }
        )
        // lib.optionalAttrs (supports "nixos") {
          nixos =
            let
              desktop = homeFor "nixos";
            in
            assert builtins.hasAttr "rofi/config.rasi" desktop.config.xdg.configFile;
            assert desktop.config.home.pointerCursor.name == "Bibata-Modern-Classic";
            assert desktop.config.gtk.cursorTheme.name == "Bibata-Modern-Classic";
            assert builtins.hasAttr "kitty/kitty.conf" desktop.config.xdg.configFile;
            assert lib.hasInfix "background_opacity 0.6" desktop.config.xdg.configFile."kitty/kitty.conf".text;
            assert lib.hasInfix "no_hardware_cursors = true" (
              builtins.readFile ./modules/nixos/desktop/hyprland/hyprland.lua
            );
            assert lib.hasInfix "hl.plugin.load(\"/etc/hyprland-plugins/libhyprbars.so\")" (
              builtins.readFile ./modules/nixos/desktop/hyprland/hyprland.lua
            );
            assert lib.hasInfix "require(\"style\")" (
              builtins.readFile ./modules/nixos/desktop/hyprland/hyprland.lua
            );
            assert lib.hasInfix "nix-home/root" (
              builtins.readFile ./modules/nixos/desktop/hyprland/link-hyprland.sh
            );
            assert lib.hasInfix "link-hyprland" desktop.config.home.activation.linkHyprland.data;
            desktop.activationPackage;

          nixos-module =
            let
              moduleConfig = self.nixosModules.desktop {
                inherit pkgs;
                inherit lib;
              };
              features = moduleConfig.nix.settings.experimental-features.content;
            in
            assert builtins.elem "nix-command" features;
            assert builtins.elem "flakes" features;
            assert moduleConfig.programs.nix-ld.enable;
            assert
              moduleConfig.programs.nix-ld.libraries == (with pkgs; [
                glib
                alsa-lib
                wayland
                libdrm
                libgbm
                libglvnd
                libx11
                vulkan-loader
              ]);
            assert moduleConfig.services.greetd.enable;
            assert moduleConfig.services.greetd.useTextGreeter;
            assert lib.hasInfix "start-hyprland" moduleConfig.services.greetd.settings.default_session.command;
            assert
              moduleConfig.environment.etc."hyprland-plugins/libhyprbars.so".source
              == "${pkgs.hyprlandPlugins.hyprbars}/lib/libhyprbars.so";
            assert moduleConfig.programs.dconf.enable;
            assert moduleConfig.services.flatpak.enable;
            assert moduleConfig.services.openssh.enable;
            assert moduleConfig.virtualisation.docker.enable;
            assert moduleConfig.virtualisation.docker.package.pname == "docker";
            assert moduleConfig.users.users.xray.extraGroups == [ "docker" ];
            pkgs.runCommand "nixos-module-check" { } ''
              touch "$out"
            '';

        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);
    };
}
