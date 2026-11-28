"""Check the Rofi clipboard-history picker against fake cliphist, rofi, and wl-copy."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(os.environ.get(
    "CLIPBOARD_HISTORY_SCRIPT",
    Path(__file__).resolve().parents[1] / "modules/desktop/clipboard/clipboard-history",
))
BASH = shutil.which("bash")

# `list` prints $FAKE/history; decode/delete/wipe log the call and the stdin they got.
FAKE_CLIPHIST = """#!/bin/sh
case "$1" in
  list) cat "$FAKE/history" ;;
  decode) printf 'decoded:'; cut -f2 ;;
  *) printf '%s:%s\\n' "$1" "$(cat 2>/dev/null)" >> "$FAKE/cliphist.log"; [ "$1" = delete ] && : > "$FAKE/history" ;;
esac
"""
# Each call takes the next "exit-code row" from $FAKE/answers and prints that row.
FAKE_ROFI = """#!/bin/sh
cat > /dev/null
line=$(head -n1 "$FAKE/answers"); sed -i 1d "$FAKE/answers"
printf '%s\\n' "${line#* }"
exit "${line%% *}"
"""
FAKE_WL_COPY = """#!/bin/sh
if [ "$1" = --clear ]; then echo cleared >> "$FAKE/clipboard"; else cat >> "$FAKE/clipboard"; fi
"""


class ClipboardHistoryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nix-home-clipboard-")
        self.addCleanup(self.temp.cleanup)
        self.fake = Path(self.temp.name)
        bin_dir = self.fake / "bin"
        bin_dir.mkdir()
        for name, body in (
            ("cliphist", FAKE_CLIPHIST),
            ("rofi", FAKE_ROFI),
            ("wl-copy", FAKE_WL_COPY),
            ("notify-send", "#!/bin/sh\n:\n"),
        ):
            path = bin_dir / name
            path.write_text(body)
            path.chmod(0o755)
        (self.fake / "history").write_text("2\tsecond copy\n1\tfirst copy\n")
        self.env = dict(os.environ, FAKE=str(self.fake), PATH=f"{bin_dir}:{os.environ['PATH']}")

    def pick(self, *answers):
        (self.fake / "answers").write_text("".join(f"{answer}\n" for answer in answers))
        result = subprocess.run([BASH, str(SCRIPT)], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def read(self, name):
        path = self.fake / name
        return path.read_text() if path.exists() else ""

    def test_enter_copies_the_decoded_entry(self):
        self.pick("0 1\tfirst copy")
        self.assertEqual(self.read("clipboard"), "decoded:first copy\n")

    def test_escape_changes_nothing(self):
        self.pick("1 ")
        self.assertEqual(self.read("clipboard"), "")
        self.assertEqual(self.read("cliphist.log"), "")

    def test_shift_delete_removes_the_entry_and_reopens(self):
        # After the delete the fake history is empty, so the reopened picker exits.
        self.pick("10 2\tsecond copy")
        self.assertEqual(self.read("cliphist.log"), "delete:2\tsecond copy\n")

    def test_clear_all_needs_confirmation(self):
        self.pick("11 ", "0 Keep history")
        self.assertEqual(self.read("cliphist.log"), "")
        self.pick("11 ", "0 Clear all history")
        self.assertIn("wipe:", self.read("cliphist.log"))
        self.assertIn("cleared", self.read("clipboard"))


if __name__ == "__main__":
    unittest.main()
