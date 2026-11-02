"""Exercise the commands in modules/scripts/bin with tmux and caddy mocked."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


BIN = Path(os.environ.get("SCRIPTS_BIN", Path(__file__).resolve().parents[1] / "modules/scripts/bin"))
BASH = shutil.which("bash")

# Logs each call; `tmux has-session` exits with BIN_TEST_HAS_SESSION_EXIT.
MOCK = f"""#!{sys.executable}
import json, os, sys
with open(os.environ['BIN_TEST_LOG'], 'a') as log:
    log.write(json.dumps([os.path.basename(sys.argv[0]), *sys.argv[1:]]) + '\\n')
if sys.argv[1:2] == ['has-session']:
    sys.exit(int(os.environ.get('BIN_TEST_HAS_SESSION_EXIT', '1')))
"""


class BinScriptTestCase(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nix-home-bin-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        mocks = self.root / "mocks"
        mocks.mkdir()
        for tool in ["tmux", "caddy"]:
            (mocks / tool).write_text(MOCK)
            (mocks / tool).chmod(0o755)
        self.log = self.root / "calls"
        self.env = dict(os.environ, PATH=f"{mocks}:{os.environ['PATH']}", BIN_TEST_LOG=str(self.log))
        self.env.pop("TMUX", None)

    def invoke(self, script, *args, cwd=None):
        return subprocess.run([BASH, str(BIN / script), *args], cwd=cwd or self.root,
                              env=self.env, text=True, capture_output=True)

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []


class TmTests(BinScriptTestCase):
    def test_defaults_to_the_directory_name(self):
        project = self.root / "my.project:two"
        project.mkdir()
        result = self.invoke("tm", cwd=project)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [["tmux", "new-session", "-A", "-s", "my_project_two", "-c", str(project)]])

    def test_named_session(self):
        result = self.invoke("tm", "work")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [["tmux", "new-session", "-A", "-s", "work", "-c", str(self.root)]])

    def test_inside_tmux_creates_then_switches(self):
        self.env["TMUX"] = "/tmp/tmux-1/default,1,0"
        result = self.invoke("tm", "work")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [
            ["tmux", "has-session", "-t", "=work"],
            ["tmux", "new-session", "-d", "-s", "work", "-c", str(self.root)],
            ["tmux", "switch-client", "-t", "=work"],
        ])

    def test_inside_tmux_switches_to_an_existing_session(self):
        self.env.update(TMUX="/tmp/tmux-1/default,1,0", BIN_TEST_HAS_SESSION_EXIT="0")
        result = self.invoke("tm", "work")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [["tmux", "has-session", "-t", "=work"],
                                        ["tmux", "switch-client", "-t", "=work"]])

    def test_extra_arguments_are_rejected(self):
        result = self.invoke("tm", "a", "b")
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage: tm [NAME]", result.stderr)
        self.assertEqual(self.calls(), [])


class ServeTests(BinScriptTestCase):
    def test_defaults_to_this_directory_on_port_8000(self):
        result = self.invoke("serve")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [["caddy", "file-server", "--root", ".", "--listen", ":8000", "--browse"]])
        self.assertIn(":8000", result.stdout)

    def test_directory_and_port(self):
        shared = self.root / "shared dir"
        shared.mkdir()
        result = self.invoke("serve", str(shared), "9090")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [["caddy", "file-server", "--root", str(shared), "--listen", ":9090", "--browse"]])

    def test_bad_input_does_not_start_a_server(self):
        for args, message in [(("missing",), "Not a directory"), ((".", "http"), "Not a port number"),
                              ((".", "0"), "Not a port number"), ((".", "70000"), "Not a port number"),
                              ((".", "8000", "x"), "Usage: serve")]:
            with self.subTest(args=args):
                result = self.invoke("serve", *args)
                self.assertEqual(result.returncode, 2)
                self.assertIn(message, result.stderr)
                self.assertEqual(self.calls(), [])

    def test_leading_zero_port_is_decimal(self):
        result = self.invoke("serve", ".", "08080")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls()[0][5], ":8080")


if __name__ == "__main__":
    unittest.main()
