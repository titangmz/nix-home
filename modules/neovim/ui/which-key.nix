{
  programs.nixvim.plugins = {
    which-key = {
      enable = true;
      settings = {
        delay = 250;
        spec = [
          {
            __unkeyed-1 = "<leader>a";
            group = "AI";
          }
          {
            __unkeyed-1 = "<leader>b";
            group = "Buffers";
          }
          {
            __unkeyed-1 = "<leader>c";
            group = "Code";
          }
          {
            __unkeyed-1 = "<leader>f";
            group = "Find";
          }
          {
            __unkeyed-1 = "<leader>g";
            group = "Git";
          }
          {
            __unkeyed-1 = "<leader>l";
            group = "Layouts";
          }
          {
            __unkeyed-1 = "<leader>r";
            group = "Run";
          }
          {
            __unkeyed-1 = "<leader>t";
            group = "Terminal";
          }
          {
            __unkeyed-1 = "<leader>w";
            group = "Windows";
          }
          {
            __unkeyed-1 = "<leader>x";
            group = "Diagnostics";
          }
        ];
        win = {
          border = "rounded";
          padding = [
            2
            2
            2
            2
          ];
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
