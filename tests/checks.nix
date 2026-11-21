# Flake checks for one system. Each asserts facts about the evaluated
# configurations, or runs the script and editor tests in this directory.
{
  self,
  lib,
  pkgs,
  system,
  profiles,
}:
let
  supports = name: builtins.elem system profiles.${name};
  homeFor = name: self.homeConfigurations."${name}-${system}";
  hasPackage = home: pname: lib.any (pkg: (pkg.pname or "") == pname) home.config.home.packages;
  # Neovim keeps these on its own PATH, outside home.packages.
  hasEditorTool =
    home: prefix:
    lib.any (pkg: lib.hasPrefix prefix pkg.name) (
      home.config.programs.nixvim.extraPackages ++ home.config.programs.nixvim.extraPackagesAfter
    );
  developmentEditorTools = [
    "rust-analyzer"
    "rustc"
    "cargo"
    "clippy"
    "rustfmt"
    "nodejs"
    "typescript"
    "vtsls"
    "go-"
    "gopls"
    "nixd"
  ];
  rustTools = [
    "rust-analyzer"
    "rustc"
    "cargo"
    "clippy"
    "rustfmt"
  ];
  # A project's own toolchain must win over the editor's, so the editor's sits
  # after the inherited PATH.
  editorToolLeads =
    home: prefix:
    lib.any (pkg: lib.hasPrefix prefix pkg.name) home.config.programs.nixvim.extraPackages;
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
  # `tools` are what the editor expects from the machine rather than carrying
  # itself, such as the C linker a Rust build needs.
  neovimCheck =
    name: home: script: tools:
    let
      editor = home.config.programs.nixvim;
    in
    pkgs.runCommand name { nativeBuildInputs = tools; } ''
      export XDG_CONFIG_HOME="$TMPDIR/config"
      export XDG_CACHE_HOME="$TMPDIR/cache"
      export XDG_DATA_HOME="$TMPDIR/data"
      export XDG_STATE_HOME="$TMPDIR/state"
      mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"
      # Editor plugins that read their own config, such as zk, get the generated one.
      if [ -d ${home.config.home-files}/.config/zk ]; then
        ln -s ${home.config.home-files}/.config/zk "$XDG_CONFIG_HOME/zk"
      fi
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
    assert !(hasPackage server "hyprshot");
    assert !(hasPackage server "zk");
    assert !server.config.programs.nixvim.plugins.zk.enable;
    assert lib.hasInfix ".local/bin" server.config.programs.zsh.envExtra;
    assert lib.hasInfix "command kitten ssh" server.config.programs.zsh.initContent;
    assert server.config.programs.nixvim.enable;
    assert lib.hasInfix "set -g renumber-windows on" server.config.programs.tmux.extraConfig;
    assert lib.hasInfix "set -g mode-style \"bg=#525677" server.config.programs.tmux.extraConfig;
    assert lib.all (
      i: lib.hasInfix "bind -n M-${toString i} " server.config.programs.tmux.extraConfig
    ) (lib.range 1 9);
    assert hasPackage server "mtr";
    assert hasPackage server "unzip";
    assert server.config.programs.gpg.enable;
    assert server.config.services.gpg-agent.enable;
    assert server.config.services.gpg-agent.pinentry.package == pkgs.pinentry-curses;
    assert builtins.elem "pinentry-program ${lib.getExe pkgs.pinentry-curses}" (
      lib.splitString "\n"
        server.config.home.file."${server.config.programs.gpg.homedir}/gpg-agent.conf".text
    );
    assert lib.hasInfix "export GPG_TTY=$TTY" server.config.programs.zsh.initContent;
    # zoxide is the only `z`; the Oh My Zsh plugin would keep a second history.
    assert server.config.programs.zoxide.enable;
    assert server.config.programs.zsh.oh-my-zsh.plugins == [ ];
    assert lib.all (pname: !(hasPackage server pname)) [
      "cargo"
      "go"
      "gopls"
      "fnm"
      "nodejs"
      "pnpm"
      "profanity"
      "v2rayn"
      "proxychains-ng"
      "cowsay"
      "lolcat"
      "rustscan"
      "tor"
    ];
    assert !(builtins.hasAttr ".proxychains/proxychains.conf" server.config.home.file);
    assert lib.all (tool: !(hasEditorTool server tool)) (
      developmentEditorTools ++ [ "vscode-lldb-adapter" ]
    );
    assert !server.config.programs.nixvim.plugins.rustaceanvim.enable;
    assert !server.config.programs.nixvim.plugins.dap.enable;
    assert !server.config.programs.nixvim.plugins.crates.enable;
    assert builtins.length server.config.programs.nixvim.plugins.treesitter.grammarPackages < 50;
    server.activationPackage;
  server-neovim = neovimCheck "server-neovim-smoke-check" server ./neovim-server.lua [ ];
  # Every shell script, including the template without a shebang, plus Nix lints.
  lint =
    pkgs.runCommand "lint-check"
      {
        nativeBuildInputs = [
          pkgs.shellcheck
          pkgs.statix
          pkgs.deadnix
        ];
      }
      ''
        cd ${self}
        # A path: flake source includes .git, whose sample hooks are not ours.
        mapfile -t scripts < <({
          grep -rlE --exclude-dir=.git '^#!.*\b(ba)?sh\b' .
          find . -path ./.git -prune -o -name '*.sh' -print
        } | sort -u)
        shellcheck "''${scripts[@]}"
        statix check --config tests/statix.toml .
        deadnix --fail .
        touch "$out"
      '';
  switch =
    let
      # These scripts drive NixOS and Hyprland, which run only on Linux.
      linuxScriptTests = lib.optionalString pkgs.stdenv.isLinux ''
        REBUILD_SCRIPT=${../scripts/rebuild.sh} python ${./test_rebuild.py}
        SETUP_MONITORS_SCRIPT=${../scripts/setup-monitors.sh} python ${./test_setup_monitors.py}
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
        SWITCH_SCRIPT=${../scripts/switch.sh} python ${./test_switch.py}
        BOOTSTRAP_SCRIPT=${../bootstrap.sh} python ${./test_bootstrap.py}
        ${linuxScriptTests}
        SCRIPTS_BIN=${../modules/scripts/bin} python ${./test_bin_scripts.py}
        SET_WALLPAPER_SCRIPT=${../modules/nixos/desktop/wallpaper/set-wallpaper} python ${./test_set_wallpaper.py}
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
      assert !(hasPackage workstation "hyprshot");
      assert hasPackage workstation "zk";
      assert hasPackage workstation "go";
      assert hasPackage workstation "gopls";
      assert hasPackage workstation "nodejs";
      assert hasPackage workstation "pnpm";
      assert workstation.config.programs.nixvim.plugins.zk.enable;
      assert
        workstation.config.home.sessionVariables.ZK_NOTEBOOK_DIR
        == "${workstation.config.home.homeDirectory}/notes";
      assert !(builtins.hasAttr "xfconfd" workstation.config.systemd.user.services);
      assert !(builtins.hasAttr "desktop-wallpaper" workstation.config.systemd.user.services);
      assert hasPackage workstation "v2rayn";
      assert hasPackage workstation "proxychains-ng";
      assert lib.all (hasEditorTool workstation) developmentEditorTools;
      assert lib.all (tool: !(editorToolLeads workstation tool)) rustTools;
      # The nixpkgs debugger works on Linux only; macOS uses Apple's lldb-dap.
      assert pkgs.stdenv.isLinux == hasEditorTool workstation "vscode-lldb-adapter";
      # TODO: also assert editor.plugins.dap.enable once the debugger is back (see
      # `debugger` in modules/neovim/development).
      assert editor.plugins.rustaceanvim.enable;
      # rustaceanvim starts rust-analyzer itself; a second client would double every diagnostic.
      assert !editor.plugins.lsp.servers.rust_analyzer.enable;
      assert
        workstation.config.programs.nixvim.plugins.treesitter.grammarPackages
        == workstation.config.programs.nixvim.plugins.treesitter.package.passthru.allGrammars;
      assert lib.hasInfix "socks5 127.0.0.1 10808" (
        builtins.readFile workstation.config.home.file.".proxychains/proxychains.conf".source
      );
      assert
        pkgs.stdenv.isDarwin
        == builtins.hasAttr "Library/Application Support/com.mitchellh.ghostty/config" workstation.config.home.file;
      assert
        pkgs.stdenv.isDarwin
        ->
          lib.hasInfix "macos-option-as-alt = left"
            workstation.config.home.file."Library/Application Support/com.mitchellh.ghostty/config".text;
      # macOS apps must be copied, never linked into /nix/store, or opening one
      # lets macOS protect the store path and garbage collection fails on it.
      assert pkgs.stdenv.isDarwin -> workstation.config.targets.darwin.copyApps.enable;
      assert !(lib.any (lib.hasPrefix "Applications/") (builtins.attrNames workstation.config.home.file));
      workstation.activationPackage;
    neovim =
      assert builtins.length mappingKeys == builtins.length (lib.unique mappingKeys);
      neovimCheck "neovim-smoke-check" workstation ./neovim.lua [ pkgs.stdenv.cc ];
  }
)
// lib.optionalAttrs (supports "nixos") {
  nixos =
    let
      desktop = homeFor "nixos";
    in
    assert builtins.hasAttr "rofi/config.rasi" desktop.config.xdg.configFile;
    assert hasPackage desktop "hyprshot";
    assert desktop.config.home.pointerCursor.name == "Bibata-Modern-Classic";
    assert desktop.config.gtk.cursorTheme.name == "Bibata-Modern-Classic";
    assert builtins.hasAttr "kitty/kitty.conf" desktop.config.xdg.configFile;
    assert lib.hasInfix "background_opacity 0.6" desktop.config.xdg.configFile."kitty/kitty.conf".text;
    assert lib.hasInfix "no_hardware_cursors = true" (
      builtins.readFile ../modules/nixos/desktop/hyprland/hyprland.lua
    );
    assert lib.hasInfix "hl.plugin.load(\"/etc/hyprland-plugins/libhyprbars.so\")" (
      builtins.readFile ../modules/nixos/desktop/hyprland/hyprland.lua
    );
    assert lib.hasInfix "require(\"style\")" (
      builtins.readFile ../modules/nixos/desktop/hyprland/hyprland.lua
    );
    assert lib.hasInfix "nix-home/root" (
      builtins.readFile ../modules/nixos/desktop/hyprland/link-hyprland.sh
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
    assert
      moduleConfig.users.users.${(import ../profiles/user.nix).username}.extraGroups == [ "docker" ];
    pkgs.runCommand "nixos-module-check" { } ''
      touch "$out"
    '';

}
