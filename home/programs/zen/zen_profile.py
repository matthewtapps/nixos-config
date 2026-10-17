import configparser
from dataclasses import dataclass, field
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
        pid = int(target.rpartition("+")[2])
    except (OSError, ValueError):
        return False
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        # Alive under another user; treat as running.
        pass
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


TOOLBAR_FOLDER = "[toolbar]"
PIN_FIELDS = ("url", "isEssential", "folderParentId", "workspace", "folderIcon")
REVERT_TEXT = {
    "restart": "reverts on the next Zen start",
    "switch": "reverts on the next switch",
    "edit": "edits Zen's files; needs this profile's Zen closed",
}


@dataclass
class Diff:
    kind: str
    ident: str
    change: str
    live: object
    config: object
    label: str
    revert: str
    extra: dict = field(default_factory=dict)


def show(value):
    return "(absent)" if value is None else json.dumps(value, ensure_ascii=False)


def ignored(ignore, kind, ident):
    return any(ident == p or (p.endswith("*") and ident.startswith(p[:-1])) for p in ignore.get(kind, []))


def _show_path(path):
    return "/".join("Toolbar" if p == TOOLBAR_FOLDER else p for p in path) or "Menu"


def flatten_bookmarks(tree, path=()):
    out = []
    for e in tree:
        if "bookmarks" in e:
            out += flatten_bookmarks(e["bookmarks"], path + (TOOLBAR_FOLDER if e.get("toolbar") else e.get("name", ""),))
        elif e.get("url"):
            out.append((path, e["url"], e.get("name", "")))
    return out


def diff_bookmarks(live, config):
    lf, cf = flatten_bookmarks(live), flatten_bookmarks(config)
    L = {(p, u): n for p, u, n in lf}
    C = {(p, u): n for p, u, n in cf}
    only_live = [k for k in L if k not in C]
    only_config = [k for k in C if k not in L]
    diffs = []
    for k in list(only_live):
        url = k[1]
        if [u for _, u in only_live].count(url) == 1 and [u for _, u in only_config].count(url) == 1:
            ck = next(c for c in only_config if c[1] == url)
            diffs.append(Diff("bookmark", url, "moved",
                              {"path": k[0], "url": url, "name": L[k]}, {"path": ck[0], "url": url, "name": C[ck]},
                              f"{_show_path(ck[0])} -> {_show_path(k[0])}: {L[k] or url}", "restart"))
            only_live.remove(k)
            only_config.remove(ck)
    for p, u in only_live:
        diffs.append(Diff("bookmark", f"{_show_path(p)}|{u}", "added", {"path": p, "url": u, "name": L[(p, u)]},
                          None, f"{_show_path(p)}: {L[(p, u)] or u}", "restart"))
    for p, u in only_config:
        diffs.append(Diff("bookmark", f"{_show_path(p)}|{u}", "removed", None, {"path": p, "url": u, "name": C[(p, u)]},
                          f"{_show_path(p)}: {C[(p, u)] or u}", "restart"))
    for k in L.keys() & C.keys():
        if L[k] != C[k]:
            p, u = k
            diffs.append(Diff("bookmark", f"{_show_path(p)}|{u}", "renamed", {"path": p, "url": u, "name": L[k]},
                              {"path": p, "url": u, "name": C[k]}, f"{_show_path(p)}: {C[k]!r} -> {L[k]!r}", "restart"))
    for folder in sorted({p for p, _ in L} & {p for p, _ in C}):
        lo = [u for p, u, _ in lf if p == folder and (p, u) in C]
        co = [u for p, u, _ in cf if p == folder and (p, u) in L]
        if lo != co:
            diffs.append(Diff("bookmark", f"order:{_show_path(folder)}", "reordered", lo, co,
                              f"{_show_path(folder)}: order changed", "restart", {"path": folder}))
    return diffs


def _pin_label(p):
    kind = "essential" if p.get("isEssential") else "folder" if p.get("isGroup") else "pin"
    return f"{kind}: {p.get('title') or p.get('url') or p['id']}"


def diff_pins(live_spaces, live_pins, config):
    diffs = []
    cp = {p["id"]: p for p in config.get("pins", [])}
    lp = {p["id"]: p for p in live_pins}
    for i, p in lp.items():
        if i not in cp:
            diffs.append(Diff("pin", i, "added", p, None, _pin_label(p), "edit"))
            continue
        c = cp[i]
        fields = [f for f in PIN_FIELDS if p.get(f) != c.get(f)]
        if (p.get("editedTitle") or c.get("editedTitle")) and p.get("title") != c.get("title"):
            fields.append("title")
        if fields:
            diffs.append(Diff("pin", i, "changed", p, c, f"{_pin_label(p)} ({', '.join(fields)})", "switch",
                              {"fields": fields}))
    for i, c in cp.items():
        if i not in lp:
            diffs.append(Diff("pin", i, "removed", None, c, _pin_label(c), "switch"))
    lo = [i for i in sorted(lp, key=lambda i: lp[i]["position"]) if i in cp]
    co = [i for i in sorted(cp, key=lambda i: cp[i].get("position", 1000)) if i in lp]
    if lo != co:
        diffs.append(Diff("pin", "order", "reordered", lo, co, "pin order changed", "switch",
                          {"positions": {i: lp[i]["position"] for i in lo}}))
    cs = {s["id"]: s for s in config.get("spaces", [])}
    ls = {s["id"]: s for s in live_spaces}
    for i, s in ls.items():
        if i not in cs:
            diffs.append(Diff("space", i, "added", s, None, f"space: {s['name']}", "edit"))
        elif (s["name"], s.get("icon")) != (cs[i]["name"], cs[i].get("icon")):
            diffs.append(Diff("space", i, "changed", s, cs[i], f"space: {s['name']}", "switch"))
    for i, c in cs.items():
        if i not in ls:
            diffs.append(Diff("space", i, "removed", None, c, f"space: {c['name']}", "switch"))
    return diffs


def diff_toolbar(prefs, toolbar):
    raw = prefs.get(TOOLBAR_PREF)
    if not raw:
        return []
    live = json.loads(raw).get("placements", {})
    conf = toolbar.get("placements", {})
    return [Diff("toolbar", a, "changed", live.get(a) or [], conf.get(a) or [], a, "restart")
            for a in sorted(set(live) | set(conf)) if (live.get(a) or []) != (conf.get(a) or [])]


def diff_settings(prefs, declared):
    diffs = []
    for k, v in prefs.items():
        if k == TOOLBAR_PREF:
            continue
        if k in declared:
            if v != declared[k]:
                diffs.append(Diff("setting", k, "changed", v, declared[k], f"{k} = {show(v)}", "restart"))
        else:
            diffs.append(Diff("setting", k, "added", v, None, f"{k} = {show(v)}", "edit"))
    return diffs


def shortcut_state(entry):
    mods = entry.get("modifiers") or {}
    return {"key": entry.get("key") or "", "keycode": entry.get("keycode") or "",
            "modifiers": [m for m in MODIFIERS if mods.get(m)], "disabled": bool(entry.get("disabled"))}


def _keys(state):
    if state["disabled"]:
        return "disabled"
    return "+".join(state["modifiers"] + [state["key"] or state["keycode"]])


def diff_shortcuts(live, baseline):
    diffs = []
    for i, e in live.items():
        b = baseline.get(i)
        if b is not None and shortcut_state(e) != shortcut_state(b):
            ls, bs = shortcut_state(e), shortcut_state(b)
            diffs.append(Diff("shortcut", i, "changed", ls, bs, f"{i}: {_keys(bs)} -> {_keys(ls)}", "edit"))
    return diffs


def diff_profile(profile, repo):
    ignore = repo.load("settings/ignore.json", {})
    config = repo.load(f"profiles/{profile.key}.json", {})
    diffs, notes = [], []
    if os.path.exists(profile.file("places.sqlite")):
        diffs += diff_bookmarks(read_bookmarks(profile.file("places.sqlite")), config.get("bookmarks", []))
    else:
        notes.append("bookmarks: profile not opened yet")
    if os.path.exists(profile.file("zen-sessions.jsonlz4")):
        spaces, pins, _ = session_pins(load_session(profile.file("zen-sessions.jsonlz4")))
        diffs += diff_pins(spaces, pins, config)
    else:
        notes.append("pins: profile not opened yet")
    prefs = read_prefs(profile.file("prefs.js"))
    diffs += diff_toolbar(prefs, repo.load(repo.toolbar_file(profile.key), {}))
    diffs += diff_settings(prefs, read_prefs(profile.file("user.js")))
    live_sc, base_sc = profile.file("zen-keyboard-shortcuts.json"), profile.file(BASELINE)
    if os.path.exists(live_sc) and os.path.exists(base_sc):
        diffs += diff_shortcuts(read_shortcuts(live_sc), read_baseline(base_sc))
    else:
        notes.append("shortcuts: no baseline yet; switch once with Zen closed")
    keep = [d for d in diffs
            if (d.kind == "setting" and d.change == "changed") or not ignored(ignore, d.kind, d.ident)]
    return keep, notes
