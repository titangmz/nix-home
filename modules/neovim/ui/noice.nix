# Noice draws the `:` command line and `/` search as a popup in the middle of
# the screen, and hands Neovim's messages to the snacks notifier, so errors and
# plugin notifications share one style and one history. Hover and signature
# help stay with the LSP and blink.
{
  programs.nixvim = {
    plugins.noice = {
      enable = true;
      settings = {
        cmdline = {
          enabled = true;
          view = "cmdline_popup";
        };
        # Messages and errors become snacks notifications; noice's "notify"
        # view uses snacks when its notifier is on.
        messages = {
          enabled = true;
          view = "notify";
          view_error = "notify";
          view_warn = "notify";
        };
        # Saving happens all the time; its "written" line is a quiet hint in
        # the corner, not a notification.
        routes = [
          {
            filter = {
              event = "msg_show";
              any = [
                { kind = "bufwrite"; }
                { find = "%d+B written"; }
              ];
            };
            view = "mini";
          }
        ];
        popupmenu.enabled = true;
        # snacks stays the vim.notify handler; noice only feeds it.
        notify.enabled = false;
        lsp = {
          progress.enabled = false;
          hover.enabled = false;
          signature.enabled = false;
          message.enabled = false;
          override = {
            "vim.lsp.util.convert_input_to_markdown_lines" = true;
            "vim.lsp.util.stylize_markdown" = true;
          };
        };
        presets = {
          # The search popup sits in the middle like the command line.
          bottom_search = false;
          command_palette = false;
          # Output too long for a popup opens in a split instead.
          long_message_to_split = true;
          lsp_doc_border = true;
        };
      };
    };
    colorschemes.catppuccin.settings.integrations.noice = true;
    keymaps = [
      {
        mode = "n";
        key = "<leader>un";
        action = "<cmd>lua Snacks.notifier.show_history()<CR>";
        options = {
          silent = true;
          desc = "Notification history";
        };
      }
    ];
  };
}
