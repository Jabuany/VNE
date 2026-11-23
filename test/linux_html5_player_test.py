"""Focused tests for the Linux resource reader, without a display."""

import importlib.util
import os
import tempfile
import unittest
from pathlib import Path


HELPER = Path(__file__).resolve().parents[1] / "runtime/html5/linux/player.py"
SPEC = importlib.util.spec_from_file_location("vne_linux_player", HELPER)
PLAYER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PLAYER)


class ResourceTests(unittest.TestCase):
    def test_paths_decode_once_and_reject_absolute_or_traversal_paths(self):
        self.assertEqual(PLAYER.local_path("/assets/novela%20local.js?rev=1"),
                         "assets/novela local.js")
        for request in ("//outside.invalid/a", "/%2e%2e/secret", "/x%2fy",
                        "/x%5cy", "/x%00y", "/a//b", "/C:secret"):
            with self.subTest(request=request), self.assertRaises(ValueError):
                PLAYER.local_path(request)

    def test_ranges_include_suffix_and_reject_multiple_or_invalid_ranges(self):
        self.assertEqual(PLAYER.byte_range(None, 100), (0, 100))
        self.assertEqual(PLAYER.byte_range("bytes=10-19", 100), (10, 20))
        self.assertEqual(PLAYER.byte_range("bytes=10-", 100), (10, 100))
        self.assertEqual(PLAYER.byte_range("bytes=-5", 100), (95, 100))
        for header in ("bytes=100-", "bytes=40-39", "bytes=-0", "bytes=1-2,5-6"):
            with self.subTest(header=header), self.assertRaises(ValueError):
                PLAYER.byte_range(header, 100)

    def test_regular_file_reads_and_links_and_fifos_are_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "file.txt").write_bytes(b"local")
            (root / "link.txt").symlink_to("/etc/hosts")
            os.mkfifo(root / "fifo")
            descriptor = os.open(root, os.O_PATH | os.O_DIRECTORY)
            try:
                file, size = PLAYER.open_resource(descriptor, "file.txt")
                with file:
                    self.assertEqual((file.read(), size), (b"local", 5))
                with self.assertRaises(OSError):
                    PLAYER.open_resource(descriptor, "link.txt")
                with self.assertRaises(ValueError):
                    PLAYER.open_resource(descriptor, "fifo")
            finally:
                os.close(descriptor)


if __name__ == "__main__":
    unittest.main()
