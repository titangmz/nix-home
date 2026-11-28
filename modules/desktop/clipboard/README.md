# Clipboard

`wl-clipboard` (`wl-copy`, `wl-paste`) and the `cliphist` clipboard history, NixOS desktop only.

Hyprland starts two watchers at login, one for text and one for images, that save every copy into cliphist's database in `~/.cache/cliphist`. Because the history keeps a copy, text you copied stays pasteable after the app you copied it from closes.

`clipboard-history`, installed into `~/.local/bin`, is a Rofi picker over the history. Open it with Super+Shift+V or the clipboard button in the control center's toolbar.

| Key | Action |
| --- | --- |
| Enter | Copy the entry back to the clipboard; paste it with Ctrl+V |
| Shift+Delete | Remove the entry |
| Alt+Delete | Clear the whole history, after a confirmation |

cliphist keeps the latest 750 entries. Passwords you copy are saved too; remove them with Shift+Delete or clear the history. `tests/test_clipboard_history.py` covers the picker with fake `cliphist`, `rofi`, and `wl-copy`.
