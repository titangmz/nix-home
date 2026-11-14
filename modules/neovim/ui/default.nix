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
        transparent_background = theme.neovim.transparent;
        # Popups are clear glass too: the terminal blurs what is behind the
        # window, and a float with no fill still hides the code beneath it as
        # long as winblend stays 0. A coloured rounded border marks each edge.
        float = {
          transparent = true;
          solid = false;
        };
        custom_highlights.__raw = ''
          function(C)
            local clear = { bg = C.none }
            local border = { fg = C.lavender, bg = C.none }
            return {
              NormalFloat = { fg = C.text, bg = C.none },
              FloatBorder = border,
              FloatTitle = { fg = C.mauve, bg = C.none, style = { "bold" } },
              Pmenu = { fg = C.overlay2, bg = C.none },
              PmenuSel = { bg = C.surface0, style = { "bold" } },
              BlinkCmpMenu = { fg = C.text, bg = C.none },
              BlinkCmpMenuBorder = border,
              BlinkCmpDoc = clear,
              BlinkCmpDocBorder = border,
              BlinkCmpSignatureHelp = clear,
              BlinkCmpSignatureHelpBorder = border,
              NeoTreeFloatBorder = border,
              NeoTreeFloatTitle = { fg = C.mauve, bg = C.none, style = { "bold" } },
              TelescopeBorder = border,
              TelescopePromptBorder = border,
              TelescopeResultsBorder = border,
              TelescopePreviewBorder = border,
              TelescopeSelection = { bg = C.surface0, style = { "bold" } },
              WhichKeyBorder = border,
            }
          end
        '';
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
        settings.highlights.__raw = "require('catppuccin.special.bufferline').get_theme()";
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
