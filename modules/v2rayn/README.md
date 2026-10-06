# v2rayN

[v2rayN](https://github.com/2dust/v2rayN) 7.25.4 for Linux and macOS Home Manager, including the NixOS desktop. The package is the official build, with the Xray core. The local inbound is SOCKS on `127.0.0.1:10808`.

Run `v2rayN`. On macOS the same build is linked at `~/Applications/v2rayN.app`.

The Linux launcher puts ICU and the X11 libraries on `LD_LIBRARY_PATH`. The .NET runtime loads those by name, and NixOS does not put them on the default library path.

Add a subscription in the app. Pick a node, then turn on the system proxy, or point a client at the SOCKS port:

```bash
export http_proxy=socks5h://127.0.0.1:10808
export https_proxy=socks5h://127.0.0.1:10808
export all_proxy=socks5h://127.0.0.1:10808
```

Leave TUN off. It needs root and is outside this repo.
