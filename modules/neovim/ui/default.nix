{ lib, ... }:
let
  theme = import ../../theme { inherit lib; };
in
{
  imports = [
    ./lualine.nix
    ./which-key.nix
    ./markdown.nix
    ./noice.nix
  ];
  programs.nixvim = {
    opts = {
      termguicolors = true;
      laststatus = 3;
      # Nothing is drawn on Neovim's first row, so it never runs into a tmux
      # status bar above it. Buffers are listed in the statusline instead.
      showtabline = 0;
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
            -- One selection colour, shared with the terminal and tmux.
            local selected = { bg = "#${theme.colors.selection}", style = { "bold" } }
            return {
              NormalFloat = { fg = C.text, bg = C.none },
              FloatBorder = border,
              FloatTitle = { fg = C.mauve, bg = C.none, style = { "bold" } },
              Pmenu = { fg = C.overlay2, bg = C.none },
              PmenuSel = selected,
              -- Selected code keeps its own weight; list rows go bold.
              Visual = { bg = selected.bg },
              VisualNOS = { bg = selected.bg },
              BlinkCmpMenu = { fg = C.text, bg = C.none },
              BlinkCmpMenuBorder = border,
              BlinkCmpDoc = clear,
              BlinkCmpDocBorder = border,
              BlinkCmpSignatureHelp = clear,
              BlinkCmpSignatureHelpBorder = border,
              NeoTreeFloatBorder = border,
              NeoTreeFloatTitle = { fg = C.mauve, bg = C.none, style = { "bold" } },
              NeoTreeFloatHint = { fg = C.overlay1, bg = C.none },
              TelescopeBorder = border,
              TelescopePromptBorder = border,
              TelescopeResultsBorder = border,
              TelescopePreviewBorder = border,
              TelescopeSelection = selected,
              NeoTreeCursorLine = selected,
              WhichKeyBorder = border,
              NoiceCmdlinePopup = { fg = C.text, bg = C.none },
              NoiceCmdlinePopupBorder = border,
              NoiceCmdlinePopupBorderSearch = { fg = C.yellow, bg = C.none },
              NoiceCmdlinePopupTitle = { fg = C.mauve, bg = C.none, style = { "bold" } },
              NoiceCmdlineIcon = { fg = C.mauve, bg = C.none },
              NoiceCmdlineIconSearch = { fg = C.yellow, bg = C.none },
              NoiceMini = clear,
              WinBar = clear,
              WinBarNC = clear,
              WinBarFile = { fg = C.overlay1, bg = C.none },
              WinBarFileActive = { fg = C.crust, bg = C.lavender, style = { "bold" } },
              StatusBufferActive = { fg = C.crust, bg = C.lavender, style = { "bold" } },
              StatusBufferInactive = { fg = C.overlay1, bg = C.none },
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
