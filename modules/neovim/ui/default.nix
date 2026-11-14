{ lib, ... }:
let
  theme = import ../../theme { inherit lib; };
in
{
  imports = [
    ./lualine.nix
    ./which-key.nix
  ];
  programs.nixvim = {
    opts = {
      termguicolors = true;
      laststatus = 3;
      showmode = false;
      winborder = "rounded";
    };
    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = theme.flavor;
        transparent_background = false;
        integrations = {
          blink_cmp = true;
          gitsigns = true;
          treesitter = true;
          neotree = true;
          telescope.enabled = true;
          snacks.enabled = true;
          native_lsp.enabled = true;
          which_key = true;
        };
      };
    };
    plugins = {
      web-devicons.enable = true;
      bufferline = {
        enable = true;
        settings.options = {
          diagnostics = "nvim_lsp";
          always_show_bufferline = false;
          show_close_icon = false;
          show_buffer_close_icons = false;
          separator_style = "thin";
          indicator.style = "underline";
          modified_icon = "●";
          max_name_length = 22;
          truncate_names = true;
        };
      };
      snacks = {
        enable = true;
        settings = {
          notifier = {
            enabled = true;
            timeout = 2500;
          };
          input.enabled = true;
          bufdelete.enabled = true;
          bigfile.enabled = true;
        };
      };
    };
  };
}
