import json
import os
import shutil
import sqlite3
import sys
import tempfile
import uuid

import lz4.block


def norm_id(raw):
    s = raw.strip("{}")
    try:
        return str(uuid.UUID(s))
    except ValueError:
        # Folder ids are "<ms>-<n>", not UUIDs.
        return str(uuid.uuid5(uuid.NAMESPACE_URL, "zen:" + s))


def read_bookmarks(places):
    if not os.path.exists(places):
        sys.exit(f"{places}: not found")
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


def entry_of(tab):
    initial = (tab.get("_zenPinnedInitialState") or {}).get("entry")
    if initial:
        return initial
    entries = tab.get("entries") or [{}]
    return entries[min(tab.get("index", 1), len(entries)) - 1]


def read_session(path):
    if not os.path.exists(path):
        sys.exit(f"{path}: not found")
    with open(path, "rb") as f:
        raw = f.read()
    if raw[:8] != b"mozLz40\0":
        sys.exit(f"{path}: not a mozLz4 file")
    data = json.loads(lz4.block.decompress(raw[8:]))

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
    print(f"source: {len(pinned)} pinned tabs, {skipped} placeholders, {len(folders)} folders")
    return spaces, pins


def count_bookmarks(entries):
    return sum(count_bookmarks(e["bookmarks"]) if "bookmarks" in e else 1 for e in entries)


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: zen-export <profile-dir> <out.json>")
    profile, out = sys.argv[1:]
    bookmarks = read_bookmarks(os.path.join(profile, "places.sqlite"))
    spaces, pins = read_session(os.path.join(profile, "zen-sessions.jsonlz4"))
    with open(out, "w") as f:
        json.dump({"bookmarks": bookmarks, "pins": pins, "spaces": spaces},
                  f, indent=2, sort_keys=True, ensure_ascii=False)
        f.write("\n")
    tabs = [p for p in pins if not p.get("isGroup")]
    print(f"wrote: {count_bookmarks(bookmarks)} bookmarks, {len(tabs)} pins"
          f" ({sum(p['isEssential'] for p in tabs)} essentials),"
          f" {len(pins) - len(tabs)} folders")


if __name__ == "__main__":
    main()
