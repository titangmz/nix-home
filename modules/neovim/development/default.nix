# Editor tooling for development machines: Rust, TypeScript, Go, the Nix language server, a
# task pane, a debugger, and syntax parsers for every language. Servers skip it;
# the Rust compiler and LLVM alone are about 1.5 GiB.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  map = key: action: desc: {
    mode = "n";
    inherit key action;
    options = {
      silent = true;
      inherit desc;
    };
  };
  lua = code: "<cmd>lua ${code}<CR>";
in
{
  programs.nixvim = {
    # nixvim's own default, which the shared editor narrows for servers.
    plugins.treesitter.grammarPackages =
      config.programs.nixvim.plugins.treesitter.package.passthru.allGrammars;
    extraPackages = [ pkgs.go ];
    # After the inherited PATH, so a project's own toolchain (a direnv shell, a
    # rustup override) wins over these and the analyzer matches the compiler.
    extraPackagesAfter =
      with pkgs;
      [
        rust-analyzer
        rustc
        cargo
        clippy
        rustfmt
        # Node runs and debugs TypeScript; tsc is the fallback type checker.
        nodejs
        typescript
      ]
      # codelldb, the debug adapter rustaceanvim looks for. macOS uses Apple's instead.
      ++ lib.optional pkgs.stdenv.isLinux pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter;
    dependencies.rust-analyzer.enable = false;

    plugins.lsp.servers = {
      nixd.enable = true;
      gopls.enable = true;
      vtsls.enable = true;
      # Attaches only where the project has an ESLint configuration.
      eslint.enable = true;
    };
    plugins.conform-nvim.settings.formatters_by_ft = {
      rust = [ "rustfmt" ];
      go = [ "gofmt" ];
      css = [ "prettier" ];
      scss = [ "prettier" ];
      html = [ "prettier" ];
    }
    # Biome where the project is set up for it, otherwise Prettier, and the
    # project's own copy of either before the editor's.
    // lib.genAttrs [ "typescript" "typescriptreact" "javascript" "javascriptreact" ] (_: {
      __raw = "function(bufnr) return require('workspace.ts').formatters(bufnr) end";
    });

    # Owns the rust-analyzer client, and knows what is runnable at the cursor.
    plugins.rustaceanvim = {
      enable = true;
      settings = {
        server.default_settings.rust-analyzer = {
          check.command = "clippy";
          cargo = {
            allFeatures = true;
            sysrootSrc = "${pkgs.rustPlatform.rustLibSrc}";
            # The analyzer checks in target/rust-analyzer, so it never holds
            # the build lock a task is waiting for.
            targetDir = true;
          };
        };
        tools = {
          executor.execute_command.__raw = "function(...) return require('workspace.rust').executor.execute_command(...) end";
          test_executor.execute_command.__raw = "function(...) return require('workspace.rust').executor.execute_command(...) end";
          crate_test_executor.execute_command.__raw = "function(...) return require('workspace.rust').executor.execute_command(...) end";
          enable_nextest = false;
        };
        # Loading them eagerly would build every target as soon as a file opens.
        dap.autoload_configurations = false;
        # On macOS the nixpkgs debuggers start the program and then lose it:
        # codelldb never reports a stop, and lldb-dap crashes. Apple's lldb-dap
        # from the Command Line Tools works, so the debugger there needs them.
        dap.adapter = lib.mkIf pkgs.stdenv.isDarwin "function() return { type = 'executable', command = '/usr/bin/xcrun', args = { 'lldb-dap' }, name = 'lldb' } end";
        # rustaceanvim's default asks lldb-dap to launch through a terminal,
        # which times out here; the program's output goes to the REPL instead.
        dap.configuration = lib.mkIf pkgs.stdenv.isDarwin {
          name = "Rust debug client";
          type = "lldb";
          request = "launch";
          stopOnEntry = false;
        };
      };
    };
    plugins.crates.enable = true;

    plugins.dap = {
      enable = true;
      signs = {
        dapBreakpoint.text = "●";
        dapBreakpointCondition.text = "◆";
        dapBreakpointRejected.text = "○";
        dapStopped.text = "▶";
      };
    };
    plugins.dap.adapters.servers.pwa-node = {
      host = "localhost";
      port = "\${port}";
      executable = {
        command = "${pkgs.vscode-js-debug}/bin/js-debug";
        args = [ "\${port}" ];
      };
    };
    # Scopes, watches, breakpoints, and the REPL; opens and closes with a session.
    plugins.dap-view = {
      enable = true;
      settings.auto_toggle = true;
    };

    extraFiles."lua/workspace/task.lua".source = ./task.lua;
    extraFiles."lua/workspace/rust.lua".source = ./rust.lua;
    extraFiles."lua/workspace/ts.lua".source = ./ts.lua;
    extraFiles."lua/workspace/lang.lua".source = ./lang.lua;
    # Loaded at startup: the task pane registers itself with the workspace layout.
    extraConfigLua = "require('workspace.task')";

    plugins.edgy.settings.bottom = [
      {
        ft = "workspace_task";
        title = "Output";
      }
    ];
    plugins.lualine.settings.sections.lualine_x = [
      { __unkeyed-1.__raw = "function() return require('workspace.task').status() end"; }
    ];
    plugins.which-key.settings.spec = [
      {
        __unkeyed-1 = "<leader>r";
        group = "Run";
      }
      {
        __unkeyed-1 = "<leader>d";
        group = "Debug";
      }
    ];

    keymaps = [
      (map "<leader>rr" (lua "require('workspace.lang').run()") "Run at cursor")
      (map "<leader>rt" (lua "require('workspace.lang').test()") "Test at cursor")
      (map "<leader>rT" (lua "require('workspace.lang').test_all()") "Test everything")
      (map "<leader>rc" (lua "require('workspace.lang').check()") "Check to quickfix")
      (map "<leader>rs" (lua "require('workspace.ts').script()") "Run a package script")
      (map "<leader>rl" (lua "require('workspace.task').rerun()") "Rerun the last task")
      (map "<leader>rx" (lua "require('workspace.task').stop()") "Stop the task")
      (map "<leader>ri" (lua "require('workspace.task').focus()") "Type into the task")
      (map "<leader>rd" (lua "require('workspace.lang').debug()") "Debug at cursor")
      (map "<leader>re" (lua "require('workspace.rust').expand_macro()") "Expand macro")
      (map "<leader>rE" (lua "require('workspace.rust').explain_error()") "Explain error")
      (map "<leader>to" (lua "require('workspace.task').toggle()") "Toggle task output")
      (map "<leader>db" (lua "require('dap').toggle_breakpoint()") "Toggle breakpoint")
      (map "<leader>dc" (lua "require('dap').continue()") "Continue")
      (map "<leader>do" (lua "require('dap').step_over()") "Step over")
      (map "<leader>di" (lua "require('dap').step_into()") "Step into")
      (map "<leader>dO" (lua "require('dap').step_out()") "Step out")
      (map "<leader>dx" (lua "require('dap').terminate()") "End the session")
      (map "<leader>du" "<cmd>DapViewToggle<CR>" "Toggle debugger panel")
      (map "<leader>uh"
        (lua "vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })")
        "Toggle inlay hints"
      )
    ];
  };
}
