{
  programs.nixvim.plugins = {
    which-key = {
      enable = true;
      settings = {
        win = {
          border = "rounded";
          padding = [ 2 2 2 2 ];
        };
        layout = {
          height = {
            min = 4;
            max = 25;
          };
          width = {
            min = 20;
            max = 50;
          };
          spacing = 3;
          align = "right";
        };
      };
    };
  };
}