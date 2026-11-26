"""Exercise the generated config and rendered borders on isolated tmux servers."""

import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import tempfile
import time
import unittest


class TmuxTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="tmux-test-", dir="/tmp")
        self.addCleanup(self.directory.cleanup)
        root = Path(self.directory.name)
        binary = os.environ.get("TEST_TMUX", shutil.which("tmux"))
        self.env = dict(os.environ, TERM="tmux-256color")
        self.env.pop("TMUX", None)
        self.env.pop("TMUX_PANE", None)
        self.inner = [binary, "-u", "-S", str(root / "inner"), "-f", os.environ["TMUX_CONFIG"]]
        self.outer = [binary, "-u", "-S", str(root / "outer"), "-f", "/dev/null"]
        for server in (self.inner, self.outer):
            self.addCleanup(self.run_tmux, server, "kill-server", check=False)

    def run_tmux(self, server, *args, check=True):
        result = subprocess.run(
            server + list(args), env=self.env, text=True, capture_output=True, timeout=10
        )
        if check:
            self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.rstrip("\n")

    def wait_for(self, predicate):
        deadline = time.monotonic() + 10
        last_error = None
        while time.monotonic() < deadline:
            try:
                if predicate():
                    return
            except AssertionError as error:
                last_error = error
            time.sleep(0.05)
        self.fail(f"Rendering did not settle: {last_error}")

    @staticmethod
    def decode(capture):
        grid, foreground = {}, None
        for y, line in enumerate(capture.splitlines()):
            x = 0
            for match in re.finditer(r"\x1b\[([0-9;]*)m|([^\x1b])", line):
                if match[1] is None:
                    grid[x, y] = match[2], foreground
                    x += 1
                    continue
                codes = [int(code or "0") for code in match[1].split(";")]
                while codes:
                    code = codes.pop(0)
                    if code in (0, 39):
                        foreground = None
                    elif code in (38, 48) and codes[:1] == [2]:
                        colour = tuple(codes[1:4])
                        del codes[:4]
                        if code == 38:
                            foreground = colour
                    elif code in (38, 48) and codes[:1] == [5]:
                        del codes[:2]
        return grid

    def assert_frames(self):
        capture = self.run_tmux(self.outer, "capture-pane", "-pe")
        grid = self.decode(capture)
        zoomed = self.run_tmux(self.inner, "display", "-p", "#{window_zoomed_flag}") == "1"
        geometry = self.run_tmux(
            self.inner, "list-panes", "-F",
            "#{pane_left} #{pane_top} #{pane_width} #{pane_height} #{pane_active}",
        )
        for line in geometry.splitlines():
            x, y, width, height, active = map(int, line.split())
            if zoomed and not active:
                continue
            style = self.run_tmux(
                self.inner, "show", "-gv",
                "pane-active-border-style" if active else "pane-border-style",
            )
            colour = tuple(bytes.fromhex(re.search(r"fg=#([0-9a-f]{6})", style)[1]))
            # The top status bar adds one row, cancelling the top border inset.
            left, top, right, bottom = x - 1, y, x + width, y + height + 1
            positions = {(col, row) for col in range(left, right + 1) for row in (top, bottom)}
            positions |= {(col, row) for row in range(top, bottom + 1) for col in (left, right)}
            for position in positions:
                char, foreground = grid.get(position, (" ", None))
                self.assertIn(char, "─│╭╮╰╯", (position, capture))
                self.assertEqual(foreground, colour, (position, capture))
        return True

    def test_config_and_full_outlines_follow_focus_and_zoom(self):
        self.run_tmux(self.inner, "new-session", "-d", "-x80", "-y24", "exec cat")
        self.run_tmux(self.inner, "set", "-g", "window-size", "manual")
        self.run_tmux(self.inner, "set", "-as", "terminal-features", ",tmux-256color:RGB")
        first = self.run_tmux(self.inner, "display", "-p", "#{pane_id}")
        second = self.run_tmux(self.inner, "split-window", "-dhP", "-F", "#{pane_id}", "exec cat")
        third = self.run_tmux(self.inner, "split-window", "-dvP", "-t", second, "-F", "#{pane_id}", "exec cat")
        self.run_tmux(self.outer, "new-session", "-d", "-x80", "-y24", "exec cat")
        self.run_tmux(self.outer, "set", "-g", "status", "off")
        self.run_tmux(self.outer, "respawn-pane", "-k", shlex.join(self.inner + ["attach-session"]))
        self.wait_for(lambda: self.run_tmux(self.inner, "list-clients", "-F", "#{client_name}"))
        self.run_tmux(self.inner, "resize-window", "-x80", "-y23")
        # Startup errors enter view mode; they must not be hidden by testing only options.
        for pane in (first, second, third):
            self.assertEqual(self.run_tmux(self.inner, "display", "-pt", pane, "#{pane_in_mode}"), "0")
        for pane in (first, second, third, first):
            self.run_tmux(self.inner, "select-pane", "-t", pane)
            self.wait_for(self.assert_frames)
        for _ in range(2):
            self.run_tmux(self.inner, "resize-pane", "-Z", "-t", first)
            self.wait_for(self.assert_frames)
        self.run_tmux(self.inner, "resize-pane", "-t", first, "-R", "3")
        self.wait_for(self.assert_frames)


if __name__ == "__main__":
    unittest.main()
