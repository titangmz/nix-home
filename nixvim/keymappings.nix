{
  programs.nixvim = {
    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    # Keymaps
    keymaps =
    [
      # nvim-tree toggle
      {
        action = ":NvimTreeToggle<CR>";
        key = "<leader>q";
        options = {
          silent = true;
          noremap = true;
          desc = "Toggle file tree";
        };
      }
      # Go to definition
      {
        action = ":lua vim.lsp.buf.definition()<CR>";
        key = "<leader>gd";
        options = {
          silent = true;
          noremap = true;
          desc = "Go to definition";
        };
      }
      # Go to references
      {
        action = ":lua vim.lsp.buf.references()<CR>";
        key = "<leader>gr";
        options = {
          silent = true;
          noremap = true;
          desc = "Go to references";
        };
      }
      # git blame toggle
      {
        action = ":GitBlameToggle<CR>";
        key = "<leader>gb";
        options = {
          silent = true;
          noremap = true;
          desc = "Toggle git blame";
        };
      }
      # git blame open URL
      {
        action = ":GitBlameOpenCommitURL<CR>";
        key = "<leader>gbu";
        options = {
          silent = true;
          noremap = true;
          desc = "Open git blame URL";
        };
      }
      # lazy git dashboard
      {
        action = ":LazyGit<CR>";
        key = "<leader>lg";
        options = {
          silent = true;
          noremap = true;
          desc = "Open lazygit";
        };
      }
      # markdown preview mapping
      {
        action = ":MarkdownPreview<CR>";
        key = "<leader>pm";
        options = {
          silent = true;
          noremap = true;
          desc = "Open markdown preview in browser";
        };
      }
      # Telescope search (live grep)
      {
        action = ":Telescope live_grep<CR>";
        key = "<leader>sg";
        options = {
          silent = true;
          noremap = true;
          desc = "Search grep";
        };
      }
      # Telescope live grep (Ctrl+F)
      {
        action = ":Telescope live_grep<CR>";
        key = "<C-f>";
        options = {
          silent = true;
          noremap = true;
          desc = "Search in files";
        };
      }
      # Telescope search buffers
      {
        action = ":Telescope buffers<CR>";
        key = "<leader>sb";
        options = {
          silent = true;
          noremap = true;
          desc = "Search buffers";
        };
      }
      # Telescope search commands
      {
        action = ":Telescope command_history<CR>";
        key = "<leader>sc";
        options = {
          silent = true;
          noremap = true;
          desc = "Search commands";
        };
      }
      # Telescope search files
      {
        action = ":Telescope find_files<CR>";
        key = "<leader>sf";
        options = {
          silent = true;
          noremap = true;
          desc = "Search files";
        };
      }
      # Telescope find files (Ctrl+P)
      {
        action = ":Telescope find_files<CR>";
        key = "<C-p>";
        options = {
          silent = true;
          noremap = true;
          desc = "Find files";
        };
      }
      # Telescope search commands
      {
        action = ":Telescope commands<CR>";
        key = "<leader>sc";
        options = {
          silent = true;
          noremap = true;
          desc = "Search commands";
        };
      }
      # Telescope undo tree
      {
        action = ":Telescope undo<CR>";
        key = "<leader>u";
        options = {
          silent = true;
          noremap = true;
          desc = "Undo tree";
        };
      }
      # Diffview open comparing in git
      {
        action = ":DiffviewOpen<CR>";
        key = "<leader>do";
        options = {
          silent = true;
          noremap = true;
          desc = "Diffview open";
        };
      }
      # Diffview close comparing in git
      {
        action = ":DiffviewClose<CR>";
        key = "<leader>dp";
        options = {
          silent = true;
          noremap = true;
          desc = "Diffview close";
        };
      }

      # Mapping Ctrl+V for block visual mode
      {
        action = "<C-v>";
        key = "<C-v>";
        options = {
          silent = true;
          noremap = true;
        };
      }

      # Buffers
      {
        action = ":BufferNext<CR>";
        key = "<Tab>";
        options = {
          silent = true;
          noremap = true;
          desc = "Next buffer";
        };
      }

      {
        action = ":BufferPrevious<CR>";
        key = "<S-Tab>";
        options = {
          silent = true;
          noremap = true;
          desc = "Prev buffer";
        };
      }
      {
        action = ":vsplit<CR>";
        key = "<leader>s";
        options = {
          silent = true;
          noremap = true;
          desc = "Vertical Split";
        };
      }
      {
        action = "<C-w>h";
        key = "<C-h>";
        options = {
          silent = true;
          noremap = true;
          desc = "Move to the pane on the left";
        };
      }
      {
        action = "<C-w>j";
        key = "<C-j>";
        options = {
          silent = true;
          noremap = true;
          desc = "Move to the pane below";
        };
      }
      {
        action = "<C-w>k";
        key = "<C-k>";
        options = {
          silent = true;
          noremap = true;
          desc = "Move to the pane above";
        };
      }
      {
        action = ":Trouble<CR>";
        key = "<leader>t";
        options = {
          silent = true;
          noremap = true;
          desc = "Open trouble window";
        };
      }
      {
        action = "<C-w>l";
        key = "<C-l>";
        options = {
          silent = true;
          noremap = true;
          desc = "Move to the pane on the right";
        };
      }
      {
        key = "<leader>b";
        action = ":DapToggleBreakpoint<CR>";
        options = {
          silent = true;
          noremap = true;
          desc = "Toggle breakpoint";
        };
      }
      {
        key = "<leader>B";
        action = ":DapClearBreakpoints<CR>";
        options = {
          silent = true;
          noremap = true;
          desc = "Clear all breakpoints";
        };
      }
      {
        key = "<leadr>dc";
        action = ":DapContinue<CR>";
        options = {
          silent = true;
          noremap = true;
          desc = "Start/Continue debugging";
        };
      }
      {
        key = "<leader>dso";
        action = ":DapStepOver<CR>";
        options = {
          silent = true;
          noremap = true;
          desc = "Step over";
        };
      }
      {
        key = "<leader>dsi";
        action = ":DapStepInto<CR>";
        options = {
          silent = true;
          noremap = true;
          desc = "Step into";
        };
      }
      {
        key = "<leader>dsO";
        action = ":DapStepOut<CR>";
        options = {
          silent = true;
          noremap = true;
          desc = "Step out";
        };
      }
      {
        key = "<leader>dr";
        action = "<cmd>lua require('dap').run_to_cursor()<CR>";
        options = {
          silent = true;
          noremap = true;
          desc = "Run to cursor";
        };
      }
      {
        key = "<leader>du";
        action = "<cmd>lua require('dapui').toggle()<CR>";
        options = {
          silent = true;
          noremap = true;
          desc = "Toggle DAP UI";
        };
      }
      {
        key = "<leader>dR";
        action = "<cmd>lua require('dap').restart()<CR>";
        options = {
          silent = true;
          noremap = true;
          desc = "Restart debugging session";
        };
      }
      {
        key = "<localleader>mi";
        action = "<cmd>MoltenInit<CR>";
        options = {
          silent = true;
          noremap = true;
          desc = "Initialize the plugin";
        };
      }
      {
        key = "<leader>ho";
        action = "<cmd>MoltenHideOutput<CR>";
        options = {
          silent = true;
          noremap = true;
          desc = "Hide output";
        };
      }
      {
        key = "<leader>eo";
        action = "<cmd>noautocmd MoltenEnterOutput<CR>";
        options = {
          silent = true;
          noremap = true;
          desc = "Enter output";
        };
      }
      {
        key = "<leader>me";
        action = "<cmd>MoltenExportOutput!<CR>";
        options = {
          silent = true;
          noremap = true;
          desc = "Export run output";
        };
      }
      {
        key = "<leader>dT";
        action = "<cmd>lua require('nvim-dap-virtual-text').refresh()<CR>";
        options = {
          silent = true;
          noremap = true;
          desc = "Refresh DAP Virtual Text";
        };
      }
    ];
  };
}