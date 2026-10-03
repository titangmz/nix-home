{ pkgs, ... }:
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
  programs.nixvim = {
    extraPackages = [ pkgs.shellcheck ];
    plugins.lsp = {
      enable = true;
      servers = {
        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
          installRustfmt = false;
          settings = {
            check.command = "clippy";
            cargo.allFeatures = true;
            cargo.sysrootSrc = "${pkgs.rustPlatform.rustLibSrc}";
          };
        };
        nixd.enable = true;
        bashls.enable = true;
        jsonls.enable = true;
        yamlls.enable = true;
        taplo.enable = true;
      };
    };
    keymaps = [
      (map "gd" "<cmd>lua vim.lsp.buf.definition()<CR>" "Go to definition")
      (map "gD" "<cmd>lua vim.lsp.buf.declaration()<CR>" "Go to declaration")
      (map "gr" "<cmd>Telescope lsp_references<CR>" "Find references")
      (map "gi" "<cmd>lua vim.lsp.buf.implementation()<CR>" "Go to implementation")
      (map "K" "<cmd>lua vim.lsp.buf.hover()<CR>" "Hover documentation")
      (map "<leader>ca" "<cmd>lua vim.lsp.buf.code_action()<CR>" "Code actions")
      (map "<leader>cr" "<cmd>lua vim.lsp.buf.rename()<CR>" "Rename symbol")
      (map "<leader>cf" "<cmd>lua require('conform').format({ lsp_format = 'fallback' })<CR>"
        "Format buffer"
      )
      (map "<leader>ct"
        "<cmd>lua vim.g.disable_autoformat = not vim.g.disable_autoformat; vim.notify('Format on save: ' .. (vim.g.disable_autoformat and 'off' or 'on'))<CR>"
        "Toggle format on save"
      )
      (map "<leader>cd" "<cmd>lua vim.diagnostic.open_float()<CR>" "Line diagnostics")
      (map "[d" "<cmd>lua vim.diagnostic.jump({ count = -1, float = true })<CR>" "Previous diagnostic")
      (map "]d" "<cmd>lua vim.diagnostic.jump({ count = 1, float = true })<CR>" "Next diagnostic")
    ];
  };
}
