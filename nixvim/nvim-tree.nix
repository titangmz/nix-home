{
  programs.nixvim.plugins = {
    nvim-tree = {
      enable = true;
      settings = {
        view = {
          float = {
            enable = true;
            open_win_config = {
              relative = "editor";
              border = "rounded";
              width = 40;
              height = 30;
              row = 1;
              col = 1;
            };
          };
          width = 30;
        };
        renderer = {
          icons = {
            show = {
              git = true;
              folder = true;
              file = true;
            };
          };
        };
        git = {
          enable = true;
        };
      };
    };
  };
}

