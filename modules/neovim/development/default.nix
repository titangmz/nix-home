# Editor tooling for development machines: Rust and the Nix language server.
# Servers skip it; the Rust compiler and LLVM alone are about 1.5 GiB.
{ pkgs, ... }:
{
  programs.nixvim = {
    # Also expose the development module's Rust tools to the standalone editor
    # wrapper used by flake checks.
    extraPackages = with pkgs; [
      rustfmt
      rustc
      cargo
      clippy
    ];
    plugins.lsp.servers = {
      rust_analyzer = {
        enable = true;
        installCargo = false;
        installRustc = false;
        installRustfmt = false;
        settings = {
          check.command = "clippy";
          cargo.allFeatures = true;
          cargo.sysrootSrc = "${pkgs.rustPlatform.rustLibSrc}";
        };
      };
      nixd.enable = true;
    };
    plugins.conform-nvim.settings.formatters_by_ft.rust = [ "rustfmt" ];
  };
}
