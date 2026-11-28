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
      ${editor.build.package}/bin/nvim --headless -i NONE --cmd "set runtimepath^=${editor.build.extraFiles}" -u ${editor.build.initFile} -c "luafile ${script}"
      touch "$out"
    '';
  # Runs Python tests from this directory; each check covers one area, so a
  # failing check names what broke.
  pythonCheck =
    name:
    {
      inputs ? [ ],
      env ? { },
    }:
    script:
    pkgs.runCommand "${name}-check" ({ nativeBuildInputs = [ pkgs.python3 ] ++ inputs; } // env) ''
      ${script}
      touch "$out"
    '';
  server = homeFor "server";
  workstationName = if pkgs.stdenv.isDarwin then "mac" else "pc";
in
{
  server = server.activationPackage;
  server-neovim = neovimCheck "server-neovim-smoke-check" server ./neovim-server.lua [ ];
  tmux =
    let
      tmux = server.config.programs.tmux.package;
    in
    pythonCheck "tmux"
      {
        inputs = [ tmux ];
        env = {
          TEST_TMUX = lib.getExe tmux;
          TMUX_CONFIG = pkgs.writeText "tmux-test.conf" server.config.xdg.configFile."tmux/tmux.conf".text;
        };
      }
      ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        python ${./test_tmux.py}
      '';
  shell = pythonCheck "shell" { inputs = [ pkgs.zsh ]; } ''
    SHELL_ZSHRC=${../modules/shell/zshrc} python ${./test_shell.py}
  '';
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
  # The scripts that install Nix and apply a profile.
  switch = pythonCheck "switch" { inputs = [ pkgs.bash ]; } ''
    SWITCH_SCRIPT=${../scripts/switch.sh} python ${./test_switch.py}
    BOOTSTRAP_SCRIPT=${../bootstrap.sh} python ${./test_bootstrap.py}
  '';
  # Commands installed into ~/.local/bin on every profile.
  bin-scripts = pythonCheck "bin-scripts" { inputs = [ pkgs.bash ]; } ''
    SCRIPTS_BIN=${../modules/scripts/bin} python ${./test_bin_scripts.py}
  '';
}
// lib.optionalAttrs pkgs.stdenv.isLinux {
  # nixos-rebuild and the Hyprland desktop scripts run only on Linux.
  desktop-scripts =
    pythonCheck "desktop-scripts"
      {
        inputs = [
          pkgs.bash
          pkgs.jq
          pkgs.lua
        ];
        env.MONITOR_LAYOUT_RUNTIME = "${../modules/desktop/hyprland}/monitor-layout.lua";
      }
      ''
        REBUILD_SCRIPT=${../scripts/rebuild.sh} python ${./test_rebuild.py}
        SETUP_MONITORS_SCRIPT=${../scripts}/setup-monitors.sh python ${./test_setup_monitors.py}
        lua ${./monitor-layout.lua}
        WAYBAR_MODULE=${../modules/desktop/waybar} CONTROL_CENTER_SCRIPT=${../modules/desktop/swaync/control-center} python ${./test_network_menu.py}
        CLIPBOARD_HISTORY_SCRIPT=${../modules/desktop/clipboard/clipboard-history} python ${./test_clipboard_history.py}
        SET_WALLPAPER_SCRIPT=${../modules/desktop/wallpaper/set-wallpaper} python ${./test_set_wallpaper.py}
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
      # A project's Rust toolchain must win over the editor's fallback tools.
      assert lib.all (tool: !(editorToolLeads workstation tool)) rustTools;
      # rustaceanvim starts rust-analyzer itself; two clients duplicate diagnostics.
      assert editor.plugins.rustaceanvim.enable -> !editor.plugins.lsp.servers.rust_analyzer.enable;
      # macOS apps must be copied, never linked into /nix/store, or opening one
      # lets macOS protect the store path and garbage collection fails on it.
      assert pkgs.stdenv.isDarwin -> workstation.config.targets.darwin.copyApps.enable;
      assert !(lib.any (lib.hasPrefix "Applications/") (builtins.attrNames workstation.config.home.file));
      workstation.activationPackage;
    neovim =
      assert builtins.length mappingKeys == builtins.length (lib.unique mappingKeys);
      neovimCheck "neovim-smoke-check" workstation ./neovim.lua [ pkgs.stdenv.cc ];
    nb =
      let
        package = builtins.head (
          builtins.filter (p: (p.pname or "") == "nb") workstation.config.home.packages
        );
      in
      pythonCheck "nb-editor" { inputs = [ pkgs.git ]; } ''
        NB_BIN=${lib.getExe package} NB_TEMPLATES=${../modules/nb/templates} python ${./test_nb.py}
      '';
  }
)
// lib.optionalAttrs (supports "nixos") {
  nixos = (homeFor "nixos").activationPackage;

  nixos-module =
    let
      moduleConfig = self.nixosModules.desktop {
        inherit pkgs;
        inherit lib;
      };
    in
    assert
      moduleConfig.environment.etc."hyprland-plugins/libhyprbars.so".source
      == "${pkgs.hyprlandPlugins.hyprbars}/lib/libhyprbars.so";
    assert
      moduleConfig.users.users.${(import ../profiles/user.nix).username}.extraGroups == [ "docker" ];
    pkgs.runCommand "nixos-module-check" { } ''
      touch "$out"
    '';

}
