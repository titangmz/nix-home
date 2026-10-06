# Waybar

Bar configuration and CSS. Colors, opacity, and blur come from `modules/theme`. Hyprland starts Waybar; there is no separate service.

The bar is one glass surface: base at the shared opacity, the inactive window border, and 12px rounding. Hyprland blurs that layer. Margins match Hyprland `gaps_out`.

Each monitor shows the title of the window on that output. The media title appears only while something is playing. Microphone and screen-share icons appear only while an app is using them. Wi-Fi shows the network name, and Ethernet shows the address.
