"""Exercise the configured nb launcher with an existing Nano environment."""

import os
import pty
import shlex
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from datetime import date


NB = os.environ.get("NB_BIN", shutil.which("nb"))
TEMPLATES = Path(os.environ.get("NB_TEMPLATES", Path(__file__).resolve().parents[1] / "modules/nb/templates"))


class NbTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nix-home-nb-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "editor.log"
        for name in ("nvim", "vi"):
            editor = self.bin / name
            editor.write_text(f'#!/bin/sh\nprintf "%s\\n" "{name}" >> "$NB_TEST_EDITOR_LOG"\nprintf "# Edited in {name}\\n" > "$1"\n')
            editor.chmod(0o755)
        nano = self.bin / "nano"
        nano.write_text("#!/bin/sh\nexit 76\n")
        nano.chmod(0o755)
        gitconfig = self.root / "gitconfig"
        gitconfig.write_text("[user]\n name = Test\n email = test@example.invalid\n")
        self.env = dict(os.environ, EDITOR="nano", NB_DIR=str(self.root / "notes with spaces"),
                        NBRC_PATH=str(self.root / "nbrc"), NB_AUTO_SYNC="0",
                        GIT_CONFIG_GLOBAL=str(gitconfig), GIT_CONFIG_NOSYSTEM="1",
                        NB_TEST_EDITOR_LOG=str(self.log), PATH=f"{self.bin}:{os.environ['PATH']}")
        self.env.pop("NB_EDITOR", None)
        self.env.pop("NB_DEFAULT_TEMPLATE", None)
        self.invoke("init")

    def invoke(self, *args, interactive=False):
        master, slave = pty.openpty()
        try:
            result = subprocess.run([NB, *args], env=self.env, cwd=self.root,
                                    stdin=slave if interactive else subprocess.DEVNULL,
                                    capture_output=True, text=True, timeout=30)
        finally:
            os.close(master)
            os.close(slave)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def test_existing_nano_environment_opens_notes_in_neovim(self):
        self.assertEqual(self.invoke("settings", "get", "editor").strip(), "nvim")
        self.invoke("add", "--filename", "editor.md", interactive=True)
        self.assertEqual(self.log.read_text(), "nvim\n")
        note = next((self.root / "notes with spaces").rglob("editor.md"))
        self.assertEqual(note.read_text(), "# Edited in nvim\n")

    def test_settings_offer_neovim_and_respect_an_explicit_choice(self):
        self.invoke("settings", "set", "editor", "vi")
        self.assertEqual(self.invoke("settings", "get", "editor").strip(), "vi")
        self.assertIn("nvim", self.invoke("settings", "show", "editor"))
        self.invoke("add", "--filename", "chosen.md", interactive=True)
        self.assertEqual(self.log.read_text(), "vi\n")

    def test_note_default_and_meeting_template_render(self):
        self.assertEqual(sorted(p.name for p in TEMPLATES.iterdir()), ["meeting.md", "note.md"])
        self.invoke("add", "--filename", "note.md", "--title", "An idea", "--content", "A useful detail")
        note = next((self.root / "notes with spaces").rglob("note.md")).read_text()
        self.assertTrue(note.startswith("# An idea\n"), note)
        self.assertIn(date.today().isoformat(), note)
        self.assertIn("A useful detail", note)
        self.assertNotIn("{{", note)
        self.invoke("add", "--filename", "meeting.md", "--template", str(TEMPLATES / "meeting.md"),
                    "--title", "Weekly meeting", "--content", "Discuss the release")
        meeting = next((self.root / "notes with spaces").rglob("meeting.md")).read_text()
        for text in ("# Weekly meeting", date.today().isoformat(), "**Attendees:**", "## Agenda",
                     "## Notes", "Discuss the release", "## Decisions", "## Action items", "- [ ]"):
            self.assertIn(text, meeting)
        self.assertNotIn("{{", meeting)

    def test_default_template_can_be_overridden_or_skipped(self):
        nbrc = self.root / "nbrc"
        with nbrc.open("a") as config:
            config.write(f"\nexport NB_DEFAULT_TEMPLATE={shlex.quote(str(TEMPLATES / 'meeting.md'))}\n")
        self.invoke("add", "--filename", "custom.md", "--content", "Custom default")
        custom = next((self.root / "notes with spaces").rglob("custom.md")).read_text()
        self.assertIn("## Agenda", custom)
        self.invoke("add", "--filename", "plain.md", "--no-template", "--content", "Plain content")
        plain = next((self.root / "notes with spaces").rglob("plain.md")).read_text()
        self.assertEqual(plain.strip(), "Plain content")


if __name__ == "__main__":
    unittest.main()
