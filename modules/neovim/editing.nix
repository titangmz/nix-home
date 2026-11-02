{ lib, pkgs, ... }:
{
  programs.nixvim = {
    opts = {
      number = true;
      relativenumber = true;
      signcolumn = "yes";
      mouse = "a";
      undofile = true;
      swapfile = false;
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
      scrolloff = 6;
      sidescrolloff = 4;
      ignorecase = true;
      smartcase = true;
      splitright = true;
      splitbelow = true;
      splitkeep = "screen";
      foldlevelstart = 99;
      updatetime = 250;
      timeoutlen = 400;
      confirm = true;
      hidden = true;
      autoread = true;
      clipboard = "unnamedplus";
    };
    extraPackages =
      with pkgs;
      [
        nixfmt
        shfmt
        nodePackages.prettier
        taplo
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
        pkgs.wl-clipboard
        pkgs.xclip
      ];
    plugins = {
      blink-cmp = {
        enable = true;
        settings.keymap = {
          "<C-q>" = [
            "cancel"
            "fallback"
          ];
          "<C-e>" = [
            "select_and_accept"
            "fallback"
          ];
        };
      };
      indent-o-matic.enable = true;
      nvim-autopairs.enable = true;
      nvim-surround.enable = true;
      treesitter = {
        enable = true;
        # Common languages for servers; modules/neovim/development restores all of them.
        grammarPackages = lib.mkDefault (
          with pkgs.vimPlugins.nvim-treesitter.builtGrammars;
          [
            bash
            c
            caddy
            css
            diff
            dockerfile
            git_config
            git_rebase
            gitattributes
            gitcommit
            gitignore
            go
            html
            ini
            javascript
            json
            lua
            luadoc
            make
            markdown
            markdown_inline
            nginx
            nix
            python
            query
            regex
            rust
            sql
            ssh_config
            toml
            typescript
            vim
            vimdoc
            xml
            yaml
          ]
        );
        nixvimInjections = true;
        folding = true;
        settings = {
          indent.enable = true;
          highlight.enable = true;
          auto_install = false;
        };
      };
      hmts.enable = true;
      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            nix = [ "nixfmt" ];
            sh = [ "shfmt" ];
            bash = [ "shfmt" ];
            json = [ "prettier" ];
            jsonc = [ "prettier" ];
            yaml = [ "prettier" ];
            markdown = [ "prettier" ];
            toml = [ "taplo" ];
          };
          format_on_save.__raw = ''
            function(buf)
              if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then return end
              return { timeout_ms = 2000, lsp_format = "never" }
            end
          '';
        };
      };
    };
    extraConfigLua = ''
      vim.diagnostic.config({
        virtual_text = false, underline = true, severity_sort = true,
        float = { border = "rounded", source = true },
      })
      vim.api.nvim_create_autocmd("FocusGained", {
        callback = function() vim.cmd.checktime() end,
      })
    '';
  };
}
