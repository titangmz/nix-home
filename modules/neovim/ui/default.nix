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
          offsets = [
            {
              filetype = "neo-tree";
              text = "Project";
              highlight = "Directory";
              text_align = "left";
            }
          ];
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
          zen = {
            enabled = true;
            center = false;
            toggles = { };
            show = {
              statusline = false;
              tabline = false;
            };
            win = {
              width = 0;
              height = 0;
              backdrop = false;
              border = "none";
            };
          };
        };
      };
    };
  };
}
