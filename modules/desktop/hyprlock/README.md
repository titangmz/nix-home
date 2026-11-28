# Hyprlock

The lock screen style, written to `~/.config/hypr/hyprlock.conf`. The hyprlock package comes from `modules/nixos`. Super+L and the Waybar session menu lock the screen.

The background is a frosted, dimmed screenshot of the desktop. Over it sit a thin clock, the date, a short accent line, a pill-shaped password field, and the current keyboard layout at the bottom. The layout is shown because Super+Space can switch to Persian and the password would then be typed wrong. The field turns the accent color while checking, red on a wrong password, and yellow with Caps Lock on.

Colors, field opacity, and the background blur and brightness come from `modules/theme`. Changes need `just switch`. The next lock uses the new style.
