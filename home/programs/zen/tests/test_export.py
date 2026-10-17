import json
import os
import subprocess
import sys
import tempfile

from conftest import FOLDER_ID, SPACE_ID, make_places, session, write_session

SCRIPT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "zen-export.py")


def run(profile, out):
    return subprocess.run([sys.executable, SCRIPT, profile, out], capture_output=True, text=True)


def test_export():
    with tempfile.TemporaryDirectory() as d:
        db = make_places(d)
        write_session(os.path.join(d, "zen-sessions.jsonlz4"), session())
        assert os.path.getsize(os.path.join(d, "places.sqlite-wal")) > 0
        out = os.path.join(d, "out.json")
        r = run(d, out)
        db.close()
        assert r.returncode == 0, r.stderr
        assert "source: 3 pinned tabs, 1 placeholders, 1 folders" in r.stdout
        assert "wrote: 3 bookmarks, 2 pins (1 essentials), 1 folders" in r.stdout
        data = json.load(open(out))
    assert data["bookmarks"] == [
        {"name": "Bookmarks Toolbar", "toolbar": True, "bookmarks": [
            {"name": "", "url": "https://a.example/"},
            {"name": "B", "url": "https://b.example/"},
        ]},
        {"name": "Dev", "bookmarks": []},
        {"name": "Other Bookmarks", "bookmarks": [{"name": "C", "url": "https://c.example/"}]},
    ]
    assert data["spaces"] == [{"id": SPACE_ID, "name": "Main", "icon": None, "position": 1000}]
    assert [p["id"] for p in data["pins"]] == [
        "11111111-1111-4111-8111-111111111111", FOLDER_ID, "22222222-2222-4222-8222-222222222222"]
    assert data["pins"][2]["title"] == "Docs" and data["pins"][2]["folderParentId"] == FOLDER_ID


def test_bad_session():
    with tempfile.TemporaryDirectory() as d:
        make_places(d).close()
        with open(os.path.join(d, "zen-sessions.jsonlz4"), "wb") as f:
            f.write(b"garbage")
        r = run(d, os.path.join(d, "out.json"))
        assert r.returncode != 0
        assert "not a mozLz4 file" in r.stderr
