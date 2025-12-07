{
  imports = [
    ./keymappings.nix
    ./lazygit.nix
    ./nix.nix
    ./which-key.nix
    ./lualine.nix
    ./tree-sitter.nix
    ./telescope.nix
    ./noice.nix
    ./comment.nix
    ./gitblame.nix
    ./nvim-tree.nix
    ./mini-icons.nix
    ./snacks.nix
    ./blink-cmp.nix
    ./indent-o-matic.nix
    ./toggleterm.nix
    ./trouble.nix
    ./line-numbers.nix
    ./claude-code.nix
  ];

  programs.nixvim = {
    colorschemes = {
      catppuccin = {
        enable = true;
        settings = {
          flavour = "mocha";
          transparent_background = true;
          integrations = {
            cmp = true;
            gitsigns = true;
            treesitter = true;
            notify = true;
            nvimtree = true;
            mini = {
              enabled = true;
            };
          };
        };
      };
      onedark = {
        enable = false;
        settings = {
          style = "cool";
        };
      };
      nightfox = {
        enable = false;
      };
      monokai-pro = {
        enable = false;
      };
      gruvbox = {
        enable = false;
        settings = {
          transparent_mode = false;
        };
      };
      kanagawa = {
        enable = false;
        settings = {
          colors = {
            palette = {
              fujiWhite = "#FFFFFF";
              sumiInk0 = "#000000";
            };
            theme = {
              all = {
                ui = {
                  bg_gutter = "none";
                };
              };
              dragon = {
                syn = {
                  parameter = "yellow";
                };
              };
              wave = {
                ui = {
                  float = {
                    bg = "none";
                  };
                };
              };
            };
          };
          commentStyle = {
            italic = true;
          };
          compile = false;
          dimInactive = false;
          functionStyle = { };
          overrides = "function(colors) return {} end";
          terminalColors = true;
          theme = "wave";
          transparent = false;
          undercurl = true;
        };
      };
    };

    plugins = {
      gitsigns = {
        enable = true;
        settings.signs = {
          add.text = "+";
          change.text = "~";
        };
      };

      transparent.enable = true;

      web-devicons.enable = true;

      nvim-autopairs.enable = true;
      none-ls.enable = true;
      nvim-surround.enable = true;

      trim = {
        enable = true;
        settings = {
          highlight = false;
          ft_blocklist = [
            "checkhealth"
            "floaterm"
            "lspinfo"
            "TelescopePrompt"
          ];
        };
      };
    };
  };
}