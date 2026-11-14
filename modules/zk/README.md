# zk

Plain Markdown notes with [zk](https://github.com/zk-org/zk), its Neovim plugin, six templates, and checkbox tasks. Only the workstation layer imports it.

The notebook is `~/notes`, exported as `ZK_NOTEBOOK_DIR`, so `zk` and the Neovim keys reach it from any directory. A switch creates `~/notes/.zk`, `journal/`, `meetings/`, `projects/`, and `prompts/`; it never touches the notes. Put the folder in Git or a synced drive yourself if you want it backed up.

The shared config is `~/.config/zk/config.toml`, generated from `default.nix`, and the templates are `~/.config/zk/templates/`, from `templates/`. A notebook's own `.zk/config.toml` or `.zk/templates/` overrides them.

| Template | Used by | File name |
| --- | --- | --- |
| `note.md` | `zk new --title "..."`, `Space nn` | `<title-slug>.md` |
| `daily.md` | `zk daily`, `Space nd` | `journal/<YYYY-MM-DD>.md`; asking again opens the existing entry |
| `meeting.md` | `zk meeting <title>`, `Space nm` | `meetings/<YYYY-MM-DD>-<title-slug>.md` |
| `project.md`: goal, scope, milestones, next actions, log | `zk project <name>`, `Space np` | `projects/<name-slug>.md` |
| `prompt.md`: just the prompt under its title | `zk prompt <name>`, `Space na` | `prompts/<name-slug>.md` |
| `todo.md`: Now, Next, Waiting, Someday, Done | `zk todo`, `Space nx` | `todo.md`; always the same file |

Tasks are Markdown checkboxes, `- [ ] ...`, in any note: the todo list, the journal's Focus, a project's next actions, or a meeting's action items. `Space nX` and `zk tasks` list every open one across the notebook, skipping the empty ones the templates leave; `Space nc` ticks or unticks the box on the current line, or turns the line into a task.

Notes link with `[[wiki links]]`; tags come from `#hashtags` or the `tags:` front matter.

Shell aliases: `zk daily`, `zk meeting <title>`, `zk project <name>`, `zk prompt <name>`, `zk projects` and `zk prompts` (pick one to open), `zk todo`, `zk tasks` (every open checkbox), `zk recent` (edited in the last two weeks), and `zk ls` (pick any note).

Neovim keys, under `Space n`:

| Key | Action |
| --- | --- |
| `Space nn` | New note; in Visual mode, a new note titled by the selection |
| `Space nd` | Today's journal |
| `Space nm` | New meeting note |
| `Space np` | New project |
| `Space na` | New AI prompt |
| `Space nx` | Todo list |
| `Space nX` | Every open task in the notebook |
| `Space nc` | Toggle the checkbox on the current line |
| `Space nf` / `Space ns` | Find notes by title / search their text |
| `Space nt` | Browse tags |
| `Space nb` / `Space nl` | Backlinks to / links from the current note |

Inside a note, the zk language server completes `[[` links, `gd` follows the link under the cursor, and `K` previews it.
