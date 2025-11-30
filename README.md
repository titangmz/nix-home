## Install Nix

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

## Enable Nix Flakes

Add this line to either `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`:
```
experimental-features = nix-command flakes
```

## Install Home Manager (standalone)

```bash
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

## Apply Configuration


```bash
./switch.sh
```
