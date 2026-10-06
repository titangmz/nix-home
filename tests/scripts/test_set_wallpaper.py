"""Check the portable wallpaper setter."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(os.environ.get(
    "SCRIPTS_DIR", Path(__file__).resolve().parents[2] / "scripts"
)) / "set-wallpaper"
BASH = shutil.which("bash")


class SetWallpaperTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nix-home-wallpaper-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.data = self.root / "data"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        systemctl = self.bin / "systemctl"
        systemctl.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$SYSTEMCTL_LOG"\n')
        systemctl.chmod(0o755)
        self.log = self.root / "systemctl.log"
        self.env = dict(
            os.environ,
            XDG_DATA_HOME=str(self.data),
            SYSTEMCTL_LOG=str(self.log),
            PATH=f"{self.bin}:{os.environ['PATH']}",
        )

    def invoke(self, *arguments, cwd=None):
        return subprocess.run(
            [BASH, str(SCRIPT), *arguments],
            cwd=cwd,
            env=self.env,
            text=True,
            capture_output=True,
        )

    def test_sets_jpg_from_relative_path_and_removes_png_override(self):
        pictures = self.root / "pictures"
        pictures.mkdir()
        (pictures / "new.jpg").write_bytes(b"jpeg-data")
        overrides = self.data / "wallpapers"
        overrides.mkdir(parents=True)
        (overrides / "override.png").write_bytes(b"old-png")

        result = self.invoke("new.jpg", cwd=pictures)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((overrides / "override.jpg").read_bytes(), b"jpeg-data")
        self.assertFalse((overrides / "override.png").exists())
        self.assertEqual(
            self.log.read_text(), "--user restart desktop-wallpaper.service\n"
        )

    def test_sets_png_and_removes_jpg_override(self):
        image = self.root / "new.PNG"
        image.write_bytes(b"png-data")
        overrides = self.data / "wallpapers"
        overrides.mkdir(parents=True)
        (overrides / "override.jpg").write_bytes(b"old-jpeg")

        result = self.invoke(str(image))

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((overrides / "override.png").read_bytes(), b"png-data")
        self.assertFalse((overrides / "override.jpg").exists())

    def test_rejects_missing_and_unsupported_files_without_restart(self):
        unsupported = self.root / "wallpaper.gif"
        unsupported.write_bytes(b"gif-data")

        self.assertNotEqual(self.invoke(str(self.root / "missing.jpg")).returncode, 0)
        self.assertNotEqual(self.invoke(str(unsupported)).returncode, 0)
        self.assertFalse(self.log.exists())
        self.assertFalse((self.data / "wallpapers").exists())

    def test_requires_exactly_one_argument(self):
        self.assertEqual(self.invoke().returncode, 2)
        self.assertEqual(self.invoke("one.png", "two.jpg").returncode, 2)


if __name__ == "__main__":
    unittest.main()
