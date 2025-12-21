{
  programs.nixvim.plugins = {
    nvim-tree = {
      enable = true;
      settings = {
        view = {
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

