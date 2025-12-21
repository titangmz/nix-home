{
  programs.nixvim = {
    plugins = {
      # Enable LSP plugin
      lsp = {
        enable = true;
        
        # Configure rust-analyzer
        servers = {
          rust_analyzer = {
            enable = true;
            installCargo = false; # Already installed in home.packages
            installRustc = false; # Already installed in home.packages
            settings = {
              check = {
                command = "clippy";
              };
              cargo = {
                allFeatures = true;
              };
            };
          };
        };
      };
    };
  };
}

