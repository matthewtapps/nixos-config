import json
import os
import sqlite3
import subprocess
import sys
import tempfile
import uuid

import lz4.block

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "zen-export.py")
SPACE = "{fd5401f0-7d54-444e-bd4c-0c3784091a9d}"
SPACE_ID = "fd5401f0-7d54-444e-bd4c-0c3784091a9d"
FOLDER = "1775537176380-73"
FOLDER_ID = str(uuid.uuid5(uuid.NAMESPACE_URL, "zen:" + FOLDER))
PLACEHOLDER = "1775537176392-19"


def tab(sync, url, essential=False, group=None, label=None):
    t = {
        "pinned": True,
        "zenEssential": essential,
        "zenSyncId": sync,
        "zenWorkspace": SPACE,
        "userContextId": 0,
        "index": 1,
        "entries": [{"url": "https://moved.example/", "title": "Moved"}],
        "_zenPinnedInitialState": {"entry": {"url": url, "title": "Page"}},
    }
    if group:
        t["groupId"] = group
    if label:
        t["zenStaticLabel"] = label
    return t


def make_profile(d):
    db = sqlite3.connect(os.path.join(d, "places.sqlite"))
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("PRAGMA wal_autocheckpoint=0")
    db.executescript("""
        CREATE TABLE moz_places (id INTEGER PRIMARY KEY, url TEXT);
        CREATE TABLE moz_bookmarks (id INTEGER PRIMARY KEY, type INTEGER,
            fk INTEGER, parent INTEGER, position INTEGER, title TEXT,
            guid TEXT);
        INSERT INTO moz_places VALUES (1, 'https://a.example/'),
            (2, 'https://b.example/'), (3, 'place:sort=8'),
            (4, 'https://c.example/');
        INSERT INTO moz_bookmarks VALUES
            (1, 2, NULL, 0, 0, '', 'root________'),
            (2, 2, NULL, 1, 0, 'menu', 'menu________'),
            (3, 2, NULL, 1, 1, 'toolbar', 'toolbar_____'),
            (4, 2, NULL, 1, 2, 'unfiled', 'unfiled_____'),
            (5, 1, 2, 3, 1, 'B', 'b'),
            (6, 1, 1, 3, 0, NULL, 'a'),
            (7, 2, NULL, 2, 0, 'Dev', 'dev'),
            (8, 3, NULL, 7, 0, NULL, 'sep'),
            (9, 1, 3, 7, 1, 'Recent', 'q'),
            (10, 1, 4, 4, 0, 'C', 'c');
    """)
    db.commit()
    session = {
        "tabs": [
            tab("{11111111-1111-4111-8111-111111111111}", "https://mail.example/", essential=True),
            tab(PLACEHOLDER, "about:blank", group=FOLDER),
            tab("{22222222-2222-4222-8222-222222222222}", "https://docs.example/", group=FOLDER, label="Docs"),
            {"pinned": False, "entries": [{"url": "https://loose.example/"}], "index": 1},
        ],
        "folders": [{
            "id": FOLDER, "name": "Work", "pinned": True, "collapsed": True,
            "parentId": None, "emptyTabIds": [PLACEHOLDER], "userIcon": "",
            "workspaceId": SPACE,
        }],
        "spaces": [{"uuid": SPACE, "name": "Main", "icon": "", "position": 1000}],
    }
    with open(os.path.join(d, "zen-sessions.jsonlz4"), "wb") as f:
        f.write(b"mozLz40\0" + lz4.block.compress(json.dumps(session).encode()))
    return db


def run(profile, out):
    return subprocess.run([sys.executable, "-I", SCRIPT, profile, out],
                          capture_output=True, text=True)


def test_export():
    with tempfile.TemporaryDirectory() as d:
        db = make_profile(d)
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
        {"name": "Other Bookmarks", "bookmarks": [
            {"name": "C", "url": "https://c.example/"},
        ]},
    ]
    assert data["spaces"] == [
        {"id": SPACE_ID, "name": "Main", "icon": None, "position": 1000},
    ]
    assert data["pins"] == [
        {"id": "11111111-1111-4111-8111-111111111111", "title": "Page",
         "editedTitle": False, "url": "https://mail.example/",
         "position": 100, "isEssential": True, "workspace": SPACE_ID,
         "container": None, "folderParentId": None},
        {"id": FOLDER_ID, "title": "Work", "isGroup": True, "position": 199,
         "isFolderCollapsed": True, "folderIcon": None,
         "workspace": SPACE_ID, "folderParentId": None},
        {"id": "22222222-2222-4222-8222-222222222222", "title": "Docs",
         "editedTitle": True, "url": "https://docs.example/",
         "position": 300, "isEssential": False, "workspace": SPACE_ID,
         "container": None, "folderParentId": FOLDER_ID},
    ]


def test_bad_session():
    with tempfile.TemporaryDirectory() as d:
        make_profile(d).close()
        with open(os.path.join(d, "zen-sessions.jsonlz4"), "wb") as f:
            f.write(b"garbage")
        r = run(d, os.path.join(d, "out.json"))
        assert r.returncode != 0
        assert "not a mozLz4 file" in r.stderr


if __name__ == "__main__":
    test_export()
    test_bad_session()
    print("ok")
