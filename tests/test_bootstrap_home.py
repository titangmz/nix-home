"""Exercise Home Manager bootstrap without activating a real profile."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(os.environ.get(
    "BOOTSTRAP_HOME_SCRIPT", Path(__file__).resolve().parents[1] / "bootstrap-home.sh"
))
BASH = shutil.which("bash")


class BootstrapHomeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nix-home-bootstrap-home-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        shutil.copy2(SCRIPT, self.repo / "bootstrap-home.sh")
        self.config_home = self.root / "config"
        self.log = self.root / "calls"
        switch = self.repo / "switch.sh"
        switch.write_text(
            f"#!{BASH}\n"
            "printf 'switch\\n' >> \"$BOOTSTRAP_HOME_TEST_LOG\"\n"
            "exit \"${BOOTSTRAP_HOME_TEST_SWITCH_EXIT:-0}\"\n"
        )
        switch.chmod(0o755)
        nix = self.root / "bin/nix"
        nix.parent.mkdir()
        nix.write_text("#!/bin/sh\nexit 0\n")
        nix.chmod(0o755)
        self.env = dict(
            os.environ,
            PATH=f"{nix.parent}:{os.environ['PATH']}",
            XDG_CONFIG_HOME=str(self.config_home),
            NIX_HOME_BOOTSTRAP_HOME_TEST="1",
            BOOTSTRAP_HOME_TEST_LOG=str(self.log),
        )

    def invoke(self):
        return subprocess.run(
            [BASH, str(self.repo / "bootstrap-home.sh")],
            cwd=self.root, env=self.env, text=True, capture_output=True,
        )

    def test_ten_runs_keep_one_flakes_line_and_the_checkout_root(self):
        for _ in range(10):
            result = self.invoke()
            self.assertEqual(result.returncode, 0, result.stderr)
        nix_conf = (self.config_home / "nix/nix.conf").read_text()
        self.assertEqual(nix_conf.count("experimental-features"), 1)
        self.assertIn("nix-command", nix_conf)
        self.assertIn("flakes", nix_conf)
        self.assertEqual((self.config_home / "nix-home/root").read_text(), f"{self.repo}\n")
        self.assertEqual(self.log.read_text().splitlines(), ["switch"] * 10)

    def test_existing_features_are_not_duplicated(self):
        nix_dir = self.config_home / "nix"
        nix_dir.mkdir(parents=True)
        (nix_dir / "nix.conf").write_text("experimental-features = nix-command flakes\n")
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            (nix_dir / "nix.conf").read_text(),
            "experimental-features = nix-command flakes\n",
        )

    def test_partial_features_gain_the_missing_token(self):
        nix_dir = self.config_home / "nix"
        nix_dir.mkdir(parents=True)
        (nix_dir / "nix.conf").write_text("experimental-features = nix-command\n")
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        line = (nix_dir / "nix.conf").read_text().strip()
        self.assertEqual(line, "experimental-features = nix-command flakes")


if __name__ == "__main__":
    unittest.main()
