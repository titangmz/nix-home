# v2rayN

[v2rayN](https://github.com/2dust/v2rayN) 7.25.4 for Linux and macOS Home Manager, including the NixOS desktop. The package is the official build, with the Xray core. The local inbound is SOCKS on `127.0.0.1:10808`.

Run `v2rayN`. On macOS the same build is linked at `~/Applications/v2rayN.app`.

The subscription URL lives in this module. Each switch writes it into v2rayN's database:

- Linux: `~/.local/share/v2rayN/guiConfigs/guiNDB.db`
- macOS: `~/Library/Application Support/v2rayN/guiConfigs/guiNDB.db`

Open v2rayN and update the Free-Configs subscription. That download fills the server list. Pick a node, then turn on the system proxy in the app, or point a client at the SOCKS port:

```bash
export http_proxy=socks5h://127.0.0.1:10808
export https_proxy=socks5h://127.0.0.1:10808
export all_proxy=socks5h://127.0.0.1:10808
```

Leave TUN off. It needs root and is outside this repo.

Close v2rayN before `just switch` when the database is open. SQLite will not take the subscription update while the app holds the file.
