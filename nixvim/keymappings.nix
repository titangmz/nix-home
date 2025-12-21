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
      # Toggle terminal
      {
        action = "<cmd>ToggleTerm<CR>";
        key = "<leader>tt";
        options = {
          silent = true;
          noremap = true;
          desc = "Toggle terminal";
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
      # Hover documentation
      {
        action = ":lua vim.lsp.buf.hover()<CR>";
        key = "K";
        options = {
          silent = true;
          noremap = true;
          desc = "Show hover documentation";
        };
      }
      # Code actions
      {
        action = ":lua vim.lsp.buf.code_action()<CR>";
        key = "<leader>ca";
        options = {
          silent = true;
          noremap = true;
          desc = "Code actions";
        };
      }
      # Rename symbol
      {
        action = ":lua vim.lsp.buf.rename()<CR>";
        key = "<leader>rn";
        options = {
          silent = true;
          noremap = true;
          desc = "Rename symbol";
        };
      }
      # Format document
      {
        action = ":lua vim.lsp.buf.format()<CR>";
        key = "<leader>f";
        options = {
          silent = true;
          noremap = true;
          desc = "Format document";
        };
      }
      # Run Rust code
      {
        action = "<cmd>TermExec cmd='cargo run'<CR>";
        key = "<leader>rr";
        options = {
          silent = true;
          noremap = true;
          desc = "Run Rust project";
        };
      }
      {
        action = "<cmd>TermExec cmd='cargo check'<CR>";
        key = "<leader>rc";
        options = {
          silent = true;
          noremap = true;
          desc = "Check Rust code";
        };
      }
      {
        action = "<cmd>TermExec cmd='cargo test'<CR>";
        key = "<leader>rt";
        options = {
          silent = true;
          noremap = true;
          desc = "Run Rust tests";
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
      # Telescope live grep (Ctrl+F)
      {
        action = ":Telescope live_grep<CR>";
        key = "<leader>fg";
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
      # Telescope find files (Ctrl+P)
      {
        action = ":Telescope find_files<CR>";
        key = "<leader>fp";
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
        key = "<leader>ss";
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
        key = "<leader>tr";
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