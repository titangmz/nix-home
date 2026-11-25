"""Exercise SSH dispatch with local and remote terminal environments."""

import os
from pathlib import Path
import subprocess
import shutil
import tempfile
import unittest


ZSHRC = Path(os.environ.get("SHELL_ZSHRC", Path(__file__).resolve().parents[1] / "modules/shell/zshrc"))


class SshTests(unittest.TestCase):
    def dispatch(self, variables, kitten=True):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("ssh", "kitten") if kitten else ("ssh",):
                script = root / name
                script.write_text(f'#!/bin/sh\nprintf "%s\\n" "{name}" "$@"\n')
                script.chmod(0o755)
            env = os.environ.copy()
            for key in ("TERM", "KITTY_WINDOW_ID", "SSH_CONNECTION", "SSH_TTY", "TERM_PROGRAM"):
                env.pop(key, None)
            env.update(variables)
            env.update(HOME=directory, PATH=directory)
            result = subprocess.run(
                [shutil.which("zsh"), "-f", "-c", 'source "$1"; ssh node1 "argument with spaces"', "test", str(ZSHRC)],
                env=env, capture_output=True, text=True, check=True,
            )
            return result.stdout.splitlines()

    def test_local_kitty(self):
        self.assertEqual(self.dispatch({"TERM": "xterm-kitty", "KITTY_WINDOW_ID": "1"}),
                         ["kitten", "ssh", "node1", "argument with spaces"])

    def test_openssh_fallbacks(self):
        cases = [
            ({"TERM": "xterm-kitty"}, True),
            ({"TERM": "xterm-kitty", "KITTY_WINDOW_ID": "1", "SSH_CONNECTION": "client 1 server 22"}, True),
            ({"TERM": "xterm-kitty", "KITTY_WINDOW_ID": "1", "SSH_TTY": "/dev/pts/1"}, True),
            ({"TERM": "xterm-256color", "KITTY_WINDOW_ID": "1"}, True),
            ({"TERM": "xterm-kitty", "KITTY_WINDOW_ID": "1"}, False),
        ]
        for variables, kitten in cases:
            with self.subTest(variables=variables, kitten=kitten):
                self.assertEqual(self.dispatch(variables, kitten),
                                 ["ssh", "node1", "argument with spaces"])


if __name__ == "__main__":
    unittest.main()
