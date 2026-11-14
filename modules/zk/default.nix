{
  config,
  lib,
  ...
}:
let
  notebook = "${config.home.homeDirectory}/notes";
  map = key: action: desc: {
    mode = "n";
    inherit key action;
    options = {
      silent = true;
      inherit desc;
    };
  };
  notes = fn: "<cmd>lua require('notes').${fn}<CR>";
in
{
  programs.zk = {
    enable = true;
    settings = {
      note = {
        language = "en";
        default-title = "Untitled";
        # Readable file names that match the [[wiki links]] to them.
        filename = "{{slug title}}";
        extension = "md";
        template = "note.md";
      };
      group.journal = {
        paths = [ "journal" ];
        note = {
          filename = "{{format-date now '%Y-%m-%d'}}";
          template = "daily.md";
        };
      };
      group.meetings = {
        paths = [ "meetings" ];
        note = {
          filename = "{{format-date now '%Y-%m-%d'}}-{{slug title}}";
          template = "meeting.md";
        };
      };
      format.markdown = {
        link-format = "wiki";
        hashtags = true;
        colon-tags = false;
        multiword-tags = false;
      };
      tool = {
        editor = "nvim";
        fzf-preview = "bat -p --color always {-1}";
      };
      lsp.diagnostics = {
        wiki-title = "hint";
        dead-link = "warning";
      };
      alias = {
        daily = ''zk new --no-input "$ZK_NOTEBOOK_DIR/journal"'';
        meeting = ''zk new --title "$*" "$ZK_NOTEBOOK_DIR/meetings"'';
        recent = "zk edit --sort modified- --modified-after 'last two weeks' --interactive";
        ls = "zk edit --interactive";
      };
    };
  };
  xdg.configFile."zk/templates".source = ./templates;
  home.sessionVariables.ZK_NOTEBOOK_DIR = notebook;
  # zk needs the notebook's .zk directory and each group's folder to exist. The
  # shared config and templates in ~/.config/zk cover everything else.
  home.activation.zkNotebook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${notebook}/.zk" "${notebook}/journal" "${notebook}/meetings"
  '';

  programs.nixvim = {
    plugins.zk = {
      enable = true;
      settings.picker = "telescope";
    };
    extraFiles."lua/notes.lua".source = ./notes.lua;
    plugins.which-key.settings.spec = [
      {
        __unkeyed-1 = "<leader>n";
        group = "Notes";
      }
    ];
    keymaps = [
      (map "<leader>nn" (notes "new()") "New note")
      (map "<leader>nd" (notes "today()") "Today's journal")
      (map "<leader>nm" (notes "new('meetings')") "New meeting note")
      (map "<leader>nf" (notes "find()") "Find notes")
      (map "<leader>ns" (notes "search()") "Search notes")
      (map "<leader>nt" (notes "tags()") "Browse tags")
      (map "<leader>nb" "<cmd>ZkBacklinks<CR>" "Backlinks to this note")
      (map "<leader>nl" "<cmd>ZkLinks<CR>" "Links from this note")
      {
        mode = "x";
        key = "<leader>nn";
        action = ":'<,'>ZkNewFromTitleSelection<CR>";
        options = {
          silent = true;
          desc = "New note titled by the selection";
        };
      }
    ];
  };
}
