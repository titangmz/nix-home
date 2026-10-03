{ pkgs, codexPackage, ... }:
let
  map = key: action: desc: {
    mode = "n";
    inherit key action;
    options = {
      silent = true;
      inherit desc;
    };
  };
in
{
  home.packages = [ codexPackage ];
  programs.nixvim = {
    # The pinned Nixvim Sidekick module requires Copilot even for CLI-only use.
    extraPlugins = [
      (pkgs.vimPlugins.sidekick-nvim.overrideAttrs (old: {
        runtimeDeps = [ ];
        patches = (old.patches or [ ]) ++ [ ./hidden-terminal.patch ];
      }))
    ];
    extraPackages = [
      codexPackage
      pkgs.lsof
    ];
    extraFiles."lua/workspace/ai.lua".source = ./ai.lua;
    extraConfigLua = "require('workspace.ai').setup()";
    keymaps = [
      (map "<leader>aa" "<cmd>lua require('workspace.ai').toggle()<CR>" "Toggle Codex")
      (map "<leader>af" "<cmd>lua require('workspace.ai').send('file')<CR>" "Send current file to Codex")
      (map "<leader>ap" "<cmd>lua require('workspace.ai').prompt()<CR>" "Choose AI prompt")
      {
        mode = "x";
        key = "<leader>av";
        action = "<cmd>lua require('workspace.ai').send('selection')<CR>";
        options = {
          silent = true;
          desc = "Send selection to Codex";
        };
      }
    ];
  };
}
