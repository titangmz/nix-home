# Wallpaper

Bundled `wallpaper.png` and the `desktop-wallpaper` user service. At startup the service uses the first readable file of `~/.local/share/wallpapers/override.png` and `override.jpg`, otherwise the bundled image.

`set-wallpaper IMAGE` copies a PNG or JPEG into the matching override, removes the other, and restarts the service. `just wallpaper` restarts it without changing the file.
