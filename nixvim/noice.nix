{
  programs.nixvim.plugins.noice = {
    enable = true;
    settings =
  {
    enable = true;
    views = {
      cmdline_popup = {
        border = {
          style = "rounded";
          padding = [ 0 1 ];
        };
        position = {
          row = 5;
          col = "50%";
        };
        size = {
          min_width = 60;
          width = "auto";
          height = "auto";
          max_height = 20;
        };
        win_options = {
          winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder";
        };
      };
    };
    notify = {
      enabled = true;
    };
    messages = {
      enabled = true; # Adds a padding-bottom to neovim statusline when set to false for some reason
    };
    lsp = {
      message = {
        enabled = true;
      };
      progress = {
        enabled = true;
        view = "mini";
      };
    };
    popupmenu = {
      enabled = true;
      backend = "nui";
    };
    format = {
      filter = {
        pattern = [":%s*%%s*s:%s*" ":%s*%%s*s!%s*" ":%s*%%s*s/%s*" "%s*s:%s*" ":%s*s!%s*" ":%s*s/%s*"];
        icon = "";
        lang = "regex";
      };
      replace = {
        pattern = [":%s*%%s*s:%w*:%s*" ":%s*%%s*s!%w*!%s*" ":%s*%%s*s/%w*/%s*" "%s*s:%w*:%s*" ":%s*s!%w*!%s*" ":%s*s/%w*/%s*"];
        icon = "󱞪";
        lang = "regex";
      };
    };
    };
  };
}