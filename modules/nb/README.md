# nb

[nb](https://xwmx.github.io/nb/) provides notes, bookmarks, search, and Git-backed
notebooks on workstation profiles. The nb launcher defaults its editor to
Neovim, including in existing shells where `EDITOR=nano` is still set. This
affects only nb. Its editor chooser is patched to include `nvim`.

Run `nb` to initialize and list notes. Notebooks live in `~/.nb` by default.
nb manages its own writable configuration; use `nb settings` to inspect or
change preferences. The module installs nb, chooses its default editor, and
provides two templates.

`nb settings set editor nvim` explicitly selects Neovim in nb's writable
configuration. Other choices made there override the launcher default. An
explicit `NB_EDITOR` environment variable takes priority, as in upstream nb.

```bash
nb add                    # create a note in Neovim
nb list                   # list notes
nb edit 1                 # edit a note by its ID
nb search 'some words'    # search notes
nb notebooks add work     # create another notebook
```

Only **note** and **meeting** templates are installed, in
`~/.config/nb/templates/`. A normal `nb add` uses the note template: title,
date, and body. The meeting template adds attendees, agenda, notes, decisions,
and action items:

```bash
nb add --title 'An idea'
nb add --template ~/.config/nb/templates/meeting.md --title 'Weekly meeting'
```

nb fills in the title, current date, and supplied content. `--no-template`
skips the template. A custom default can be selected by setting
`export NB_DEFAULT_TEMPLATE=/path/to/template` in the writable `~/.nbrc`.

Existing Markdown files in `~/notes` are kept in place. To copy selected files
or directories into nb, use `nb import /path/to/file-or-folder`. Importing is
explicit; switching profiles does not import or initialize notebooks.
