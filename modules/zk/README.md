# zk

Plain Markdown notes with [zk](https://github.com/zk-org/zk), its Neovim plugin, and three templates. Only the workstation layer imports it.

The notebook is `~/notes`, exported as `ZK_NOTEBOOK_DIR`, so `zk` and the Neovim keys reach it from any directory. A switch creates `~/notes/.zk`, `journal/`, and `meetings/`; it never touches the notes. Put the folder in Git or a synced drive yourself if you want it backed up.

The shared config is `~/.config/zk/config.toml`, generated from `default.nix`, and the templates are `~/.config/zk/templates/`, from `templates/`. A notebook's own `.zk/config.toml` or `.zk/templates/` overrides them.

| Template | Used by | File name |
| --- | --- | --- |
| `note.md` | `zk new --title "..."`, `Space nn` | `<title-slug>.md` |
| `daily.md` | `zk daily`, `Space nd` | `journal/<YYYY-MM-DD>.md`; asking again opens the existing entry |
| `meeting.md` | `zk meeting <title>`, `Space nm` | `meetings/<YYYY-MM-DD>-<title-slug>.md` |

Notes link with `[[wiki links]]`; tags come from `#hashtags` or the `tags:` front matter.

Shell aliases: `zk daily`, `zk meeting <title>`, `zk recent` (edited in the last two weeks), and `zk ls` (pick any note).

Neovim keys, under `Space n`:

| Key | Action |
| --- | --- |
| `Space nn` | New note; in Visual mode, a new note titled by the selection |
| `Space nd` | Today's journal |
| `Space nm` | New meeting note |
| `Space nf` / `Space ns` | Find notes by title / search their text |
| `Space nt` | Browse tags |
| `Space nb` / `Space nl` | Backlinks to / links from the current note |

Inside a note, the zk language server completes `[[` links, `gd` follows the link under the cursor, and `K` previews it.
