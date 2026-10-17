import configparser
import json
import os
import re
import shutil
import sqlite3
import sys
import tempfile
import uuid

import lz4.block

MAGIC = b"mozLz40\0"
TOOLBAR_PREF = "browser.uiCustomization.state"
MODIFIERS = ("accel", "alt", "control", "meta", "shift")
BASELINE = "zen-shortcuts-baseline.json"
PREF_RE = re.compile(r'^user_pref\("((?:[^"\\]|\\.)*)",\s*(.*)\);\s*$', re.M)


def norm_id(raw):
    s = raw.strip("{}")
    try:
        return str(uuid.UUID(s))
    except ValueError:
        # Folder ids are "<ms>-<n>", not UUIDs.
        return str(uuid.uuid5(uuid.NAMESPACE_URL, "zen:" + s))


def backup(path):
    if os.path.exists(path):
        shutil.copy2(path, path + ".pre-reconcile")


def read_bookmarks(places):
    if not os.path.exists(places):
        raise ValueError(f"{places}: not found")
    with tempfile.TemporaryDirectory() as tmp:
        # Zen locks the live file and keeps recent writes in the -wal.
        copy = os.path.join(tmp, "places.sqlite")
        for suffix in ("", "-wal"):
            if os.path.exists(places + suffix):
                shutil.copyfile(places + suffix, copy + suffix)
        db = sqlite3.connect(copy)
        rows = db.execute(
            "SELECT b.id, b.parent, b.type, b.title, b.guid, p.url"
            " FROM moz_bookmarks b LEFT JOIN moz_places p ON p.id = b.fk"
            " ORDER BY b.parent, b.position"
        ).fetchall()
        db.close()

    children = {}
    roots = {}
    for id_, parent, type_, title, guid, url in rows:
        children.setdefault(parent, []).append((id_, type_, title, url))
        roots[guid] = id_

    def tree(parent):
        out = []
        for id_, type_, title, url in children.get(parent, []):
            if type_ == 1 and url and not url.startswith("place:"):
                out.append({"name": title or "", "url": url})
            elif type_ == 2:
                out.append({"name": title or "", "bookmarks": tree(id_)})
        return out

    result = []
    toolbar = tree(roots.get("toolbar_____"))
    if toolbar:
        result.append({"name": "Bookmarks Toolbar", "toolbar": True, "bookmarks": toolbar})
    result += tree(roots.get("menu________"))
    other = tree(roots.get("unfiled_____"))
    if other:
        result.append({"name": "Other Bookmarks", "bookmarks": other})
    return result


def load_session(path):
    if not os.path.exists(path):
        raise ValueError(f"{path}: not found")
    with open(path, "rb") as f:
        raw = f.read()
    if raw[:8] != MAGIC:
        raise ValueError(f"{path}: not a mozLz4 file")
    return json.loads(lz4.block.decompress(raw[8:]))


def save_session(path, data):
    backup(path)
    with open(path, "wb") as f:
        f.write(MAGIC + lz4.block.compress(json.dumps(data).encode()))


def entry_of(tab):
    initial = (tab.get("_zenPinnedInitialState") or {}).get("entry")
    if initial:
        return initial
    entries = tab.get("entries") or [{}]
    return entries[min(tab.get("index", 1), len(entries)) - 1]


def session_pins(data):
    folders = [f for f in data.get("folders", []) if f.get("pinned")]
    folder_ids = {f["id"] for f in folders}
    placeholders = {t for f in folders for t in f.get("emptyTabIds", [])}
    spaces = [
        {"id": norm_id(s["uuid"]), "name": s["name"],
         "icon": s.get("icon") or None, "position": s.get("position", 1000)}
        for s in data.get("spaces", [])
    ]
    pinned = [t for t in data.get("tabs", []) if t.get("pinned") or t.get("zenEssential")]
    pins = []
    positions = {}
    skipped = 0
    for i, tab in enumerate(pinned):
        pos = (i + 1) * 100
        group = tab.get("groupId") if tab.get("groupId") in folder_ids else None
        if group:
            positions.setdefault(group, pos - 1)
        if tab.get("zenSyncId") in placeholders:
            skipped += 1
            continue
        entry = entry_of(tab)
        label = tab.get("zenStaticLabel")
        workspace = tab.get("zenWorkspace")
        pins.append({
            "id": norm_id(tab["zenSyncId"]),
            "title": label or entry.get("title") or entry.get("url") or "",
            "editedTitle": bool(label),
            "url": entry.get("url"),
            "position": pos,
            "isEssential": bool(tab.get("zenEssential")),
            "workspace": norm_id(workspace) if workspace else None,
            "container": tab.get("userContextId") or None,
            "folderParentId": norm_id(group) if group else None,
        })
    for _ in folders:
        for f in folders:
            parent = f.get("parentId")
            if parent in folder_ids and f["id"] in positions:
                positions[parent] = min(positions.get(parent, positions[f["id"]]), positions[f["id"]] - 1)
    for f in folders:
        parent = f.get("parentId")
        pins.append({
            "id": norm_id(f["id"]),
            "title": f.get("name") or "",
            "isGroup": True,
            "position": positions.get(f["id"], 1000),
            "isFolderCollapsed": bool(f.get("collapsed")),
            "folderIcon": f.get("userIcon") or None,
            "workspace": norm_id(f["workspaceId"]) if f.get("workspaceId") else None,
            "folderParentId": norm_id(parent) if parent in folder_ids else None,
        })
    pins.sort(key=lambda p: p["position"])
    return spaces, pins, {"pinned": len(pinned), "placeholders": skipped, "folders": len(folders)}


def read_prefs(path):
    if not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as f:
        text = f.read()
    return {json.loads(f'"{k}"'): json.loads(v) for k, v in PREF_RE.findall(text)}


def remove_prefs(path, keys):
    backup(path)
    with open(path, encoding="utf-8") as f:
        lines = f.readlines()
    keep = []
    for line in lines:
        m = PREF_RE.match(line)
        if not (m and json.loads(f'"{m.group(1)}"') in keys):
            keep.append(line)
    with open(path, "w", encoding="utf-8") as f:
        f.writelines(keep)


def _by_id(entries):
    return {e["id"]: e for e in entries if e.get("id")}


def read_shortcuts(path):
    with open(path) as f:
        return _by_id(json.load(f)["shortcuts"])


def read_baseline(path):
    with open(path) as f:
        return _by_id(json.load(f)["shortcuts"])


def zen_running(profile_dir):
    try:
        target = os.readlink(os.path.join(profile_dir, "lock"))
        os.kill(int(target.rpartition("+")[2]), 0)
    except (OSError, ValueError):
        return False
    return True


class Profile:
    def __init__(self, name, dir):
        self.name = name
        self.dir = dir

    @property
    def key(self):
        return os.path.basename(self.dir.rstrip("/")).lower()

    def file(self, name):
        return os.path.join(self.dir, name)


def discover(zen_dir):
    ini = configparser.ConfigParser(interpolation=None)
    ini.optionxform = str
    ini.read(os.path.join(zen_dir, "profiles.ini"))
    out = []
    for s in ini.sections():
        sec = ini[s]
        if s.startswith("Profile") and sec.get("Name") and sec.get("Path"):
            relative = sec.get("IsRelative", "1") == "1"
            out.append(Profile(sec["Name"], os.path.join(zen_dir, sec["Path"]) if relative else sec["Path"]))
    return out


class Repo:
    def __init__(self, root):
        self.zen = os.path.join(root, "home", "programs", "zen")

    def path(self, rel):
        return os.path.join(self.zen, rel)

    def load(self, rel, default):
        p = self.path(rel)
        if not os.path.exists(p):
            return default
        try:
            with open(p) as f:
                return json.load(f)
        except json.JSONDecodeError as e:
            raise ValueError(f"{p}: {e}") from None

    def save(self, rel, data):
        p = self.path(rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "w") as f:
            json.dump(data, f, indent=2, sort_keys=True, ensure_ascii=False)
            f.write("\n")
        return rel

    def toolbar_file(self, key):
        own = f"toolbar-{key}.json"
        return own if os.path.exists(self.path(own)) else "toolbar.json"


def count_bookmarks(entries):
    return sum(count_bookmarks(e["bookmarks"]) if "bookmarks" in e else 1 for e in entries)


def export_main(argv):
    if len(argv) != 2:
        sys.exit("usage: zen-export <profile-dir> <out.json>")
    profile, out = argv
    try:
        bookmarks = read_bookmarks(os.path.join(profile, "places.sqlite"))
        spaces, pins, stats = session_pins(load_session(os.path.join(profile, "zen-sessions.jsonlz4")))
    except ValueError as e:
        sys.exit(str(e))
    print(f"source: {stats['pinned']} pinned tabs, {stats['placeholders']} placeholders, {stats['folders']} folders")
    with open(out, "w") as f:
        json.dump({"bookmarks": bookmarks, "pins": pins, "spaces": spaces},
                  f, indent=2, sort_keys=True, ensure_ascii=False)
        f.write("\n")
    tabs = [p for p in pins if not p.get("isGroup")]
    print(f"wrote: {count_bookmarks(bookmarks)} bookmarks, {len(tabs)} pins"
          f" ({sum(p['isEssential'] for p in tabs)} essentials),"
          f" {len(pins) - len(tabs)} folders")
