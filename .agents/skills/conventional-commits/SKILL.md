---
name: conventional-commits
description: Write or review Conventional Commit messages when asked to commit changes or suggest a commit message.
---

For commit-only tasks, use repository instructions already in context. Do not reread `AGENTS.md` or `docs/rules.md`, or check their freshness, unless the user requests it or the diff changes those instructions. Read missing instructions once.

Inspect `git status` and the relevant diff before writing a message. For staged changes, base the message on `git diff --cached` and exclude unstaged changes from the description.

Use this format:

```text
<type>(<optional scope>): <description>
```

Choose a type that describes the change:

- `feat`: new functionality
- `fix`: bug correction
- `docs`: documentation
- `refactor`: restructuring without changing behavior
- `test`: tests
- `build`: dependencies or build configuration
- `ci`: continuous integration
- `chore`: maintenance

Use a short, imperative description. Choose a scope matching the affected module, such as `neovim`, `hyprland`, `theme`, or `scripts`. Omit the scope for broad changes.

Mark breaking changes with `!` before the colon and explain them in a `BREAKING CHANGE:` footer. Add a body when the reason or consequences need explanation.

Examples:

```text
feat(neovim): add Rust debugging shortcuts
fix(scripts): preserve saved profile during dry runs
docs: clarify bootstrap instructions
```

Follow the repository's validation requirements before committing. Reuse completed validation when it still covers the changes; rerun checks only for relevant new changes, failures, or unresolved concerns. Only create a commit when the user requests one.
