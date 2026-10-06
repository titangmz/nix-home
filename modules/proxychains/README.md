# proxychains

[proxychains-ng](https://github.com/rofl0r/proxychains-ng) for Linux and macOS Home Manager, including the NixOS desktop. It hooks a program and sends its connections through a SOCKS proxy. DNS goes through the proxy.

`proxychains.conf` in this directory is written to `~/.proxychains/proxychains.conf` on every switch. The current proxy is `127.0.0.1:10808`, which is v2rayN's local inbound.

```bash
proxychains4 curl https://www.gstatic.com/generate_204
```

On macOS, that `curl` has to be the one from this config. Apple's `/usr/bin/curl` cannot be hooked.
