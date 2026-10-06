{
  config,
  lib,
  pkgs,
  ...
}:
let
  v2rayn = pkgs.callPackage ./package.nix { };
  subscriptionId = "nix-home-free-configs";
  subscriptionUrl = "https://raw.githubusercontent.com/patterniha/Free-Configs/main/configs.txt";
  configDir =
    if pkgs.stdenv.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/v2rayN/guiConfigs"
    else
      "${config.xdg.dataHome}/v2rayN/guiConfigs";
in
{
  home.packages = [ v2rayn ];

  home.file."Applications/v2rayN.app" = lib.mkIf pkgs.stdenv.isDarwin {
    source = "${v2rayn}/Applications/v2rayN.app";
  };

  # v2rayN stores subscriptions in guiNDB.db. Keep this URL in that database
  # without touching nodes or settings created in the GUI.
  home.activation.v2raynSubscription = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config_dir=${lib.escapeShellArg configDir}
    run mkdir -p "$config_dir"
    run ${pkgs.sqlite}/bin/sqlite3 "$config_dir/guiNDB.db" <<'SQL'
    CREATE TABLE IF NOT EXISTS SubItem (
      Id TEXT PRIMARY KEY NOT NULL,
      Remarks TEXT,
      Url TEXT,
      MoreUrl TEXT,
      Enabled INTEGER NOT NULL,
      UserAgent TEXT,
      RequestHeaders TEXT,
      Sort INTEGER NOT NULL,
      Filter TEXT,
      AutoUpdateInterval INTEGER NOT NULL,
      UpdateTime INTEGER NOT NULL,
      ConvertTarget TEXT,
      PrevProfile TEXT,
      NextProfile TEXT,
      PreSocksPort INTEGER,
      Memo TEXT,
      CustomCoreType INTEGER
    );
    INSERT INTO SubItem (
      Id, Remarks, Url, MoreUrl, Enabled, UserAgent, Sort, AutoUpdateInterval, UpdateTime
    ) VALUES (
      '${subscriptionId}',
      'Free-Configs',
      '${subscriptionUrl}',
      ${"''"},
      1,
      ${"''"},
      0,
      60,
      0
    )
    ON CONFLICT(Id) DO UPDATE SET
      Remarks = excluded.Remarks,
      Url = excluded.Url,
      Enabled = excluded.Enabled;
    SQL
  '';
}
