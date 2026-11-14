# Markdown rendered in the buffer: headings, checkboxes, tables, code blocks,
# and callouts. The cursor line shows the raw text, so editing stays plain.
{
  programs.nixvim = {
    plugins.render-markdown = {
      enable = true;
      settings = {
        file_types = [ "markdown" ];
        anti_conceal.enabled = true;
        heading = {
          sign = false;
          width = "block";
          left_pad = 1;
          right_pad = 2;
        };
        code = {
          sign = false;
          width = "block";
          left_pad = 1;
          right_pad = 1;
        };
        # Ticked tasks are struck through so open ones stand out.
        checkbox.checked.scope_highlight = "@markup.strikethrough";
        pipe_table.style = "full";
      };
    };
    colorschemes.catppuccin.settings.integrations.render_markdown = true;
    keymaps = [
      {
        mode = "n";
        key = "<leader>um";
        action = "<cmd>RenderMarkdown toggle<CR>";
        options = {
          silent = true;
          desc = "Toggle rendered Markdown";
        };
      }
    ];
  };
}
