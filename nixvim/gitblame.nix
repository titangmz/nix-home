{
  programs.nixvim.plugins.gitblame = {
    enable = true;
    settings = {
      enabled = true;
      message_template = "<author> • <date> • <summary>";
      date_format = "%r";
      delay = 1000;
      display_virtual_text = true;
    };
  };
}