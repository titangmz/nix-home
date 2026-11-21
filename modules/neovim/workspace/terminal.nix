let
  mapIn = mode: key: action: desc: {
    inherit mode key action;
    options = {
      silent = true;
      inherit desc;
    };
  };
  toggle = "<cmd>lua require('workspace.terminal').toggle()<CR>";
in
{
  programs.nixvim = {
    # Only Lazygit's float goes through ToggleTerm; the shell is workspace.terminal.
    plugins.toggleterm = {
      enable = true;
      settings = {
        shade_terminals = false;
        start_in_insert = false;
        persist_mode = false;
        close_on_exit = false;
        # Lazygit's float stays solid over a transparent editor.
        highlights = {
          NormalFloat.link = "NormalFloat";
          FloatBorder.link = "FloatBorder";
        };
      };
    };
    extraFiles."lua/workspace/terminal.lua".source = ./terminal.lua;
    extraConfigLua = "require('workspace.terminal').setup()";
    # Ctrl-/ arrives as Ctrl-_ from terminals without the extended key protocol.
    # The shell buffer maps the same keys to close itself.
    keymaps = [
      (mapIn "n" "<leader>tt" toggle "Toggle shell")
    ]
    ++
      builtins.concatMap
        (key: [
          (mapIn "n" key toggle "Toggle shell")
          (mapIn "i" key toggle "Toggle shell")
        ])
        [
          "<C-/>"
          "<C-_>"
        ];
  };
}
