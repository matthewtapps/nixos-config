import configparser
from dataclasses import dataclass, field
import glob
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
    "none": "nothing to revert; bookmarks are not managed",
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
        titled = any(x.get(k) for x in (p, c) for k in ("editedTitle", "isGroup"))
        if titled and p.get("title") != c.get("title"):
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
        live_tree = read_bookmarks(profile.file("places.sqlite"))
        if "bookmarks" in config:
            diffs += diff_bookmarks(live_tree, config["bookmarks"])
        else:
            diffs.append(Diff("bookmark", "adopt", "added", live_tree, None,
                              f"{count_bookmarks(live_tree)} bookmarks, not managed; promote to adopt them all",
                              "none"))
    else:
        notes.append("bookmarks: profile not opened yet")
    if os.path.exists(profile.file("zen-sessions.jsonlz4")):
        spaces, pins, _ = session_pins(load_session(profile.file("zen-sessions.jsonlz4")))
        diffs += diff_pins(spaces, pins, config)
    else:
        notes.append("pins: profile not opened yet")
    if os.path.exists(profile.file("prefs.js")):
        prefs = read_prefs(profile.file("prefs.js"))
        toolbar = repo.load(repo.toolbar_file(profile.key), {})
        try:
            diffs += diff_toolbar(prefs, toolbar)
        except json.JSONDecodeError:
            notes.append("toolbar: unreadable layout in prefs.js")
        diffs += diff_settings(prefs, read_prefs(profile.file("user.js")))
    else:
        notes.append("toolbar and settings: profile not opened yet")
    live_sc, base_sc = profile.file("zen-keyboard-shortcuts.json"), profile.file(BASELINE)
    if not os.path.exists(live_sc):
        notes.append("shortcuts: profile not opened yet")
    elif not os.path.exists(base_sc):
        notes.append("shortcuts: no baseline yet; switch once with Zen closed")
    else:
        diffs += diff_shortcuts(read_shortcuts(live_sc), read_baseline(base_sc))

    def is_ignored(d):
        if d.kind == "setting" and d.change == "changed":
            return d.ident in ignore.get("setting", [])
        return ignored(ignore, d.kind, d.ident)

    return [d for d in diffs if not is_ignored(d)], notes


def default_target(d):
    per_profile = d.kind == "setting" and (d.ident == "zen.theme.accent-color" or d.ident.startswith("font.name."))
    return "profile" if per_profile else "shared"


@dataclass
class Action:
    diff: Diff
    verb: str
    target: str = "shared"


@dataclass
class Result:
    written: set = field(default_factory=set)
    reverted: list = field(default_factory=list)
    queued: list = field(default_factory=list)
    restart: list = field(default_factory=list)
    switch: list = field(default_factory=list)


def _folder(tree, path, create):
    level = tree
    for name in path:
        if name == TOOLBAR_FOLDER:
            node = next((e for e in level if e.get("toolbar")), None)
            if node is None and create:
                node = {"name": "Bookmarks Toolbar", "toolbar": True, "bookmarks": []}
                level.insert(0, node)
        else:
            node = next((e for e in level if "bookmarks" in e and not e.get("toolbar") and e.get("name") == name), None)
            if node is None and create:
                node = {"name": name, "bookmarks": []}
                level.append(node)
        if node is None:
            return None
        level = node["bookmarks"]
    return level


def _insert_bookmark(config, live, path, url, name):
    folder = _folder(config, path, True)
    siblings = [u for p, u, _ in flatten_bookmarks(live) if p == path]
    before = set(siblings[:siblings.index(url)]) if url in siblings else set()
    pos = 0
    for i, e in enumerate(folder):
        if e.get("url") in before:
            pos = i + 1
    folder.insert(pos, {"name": name, "url": url})


def _remove_bookmark(config, path, url):
    folder = _folder(config, path, False)
    if folder is not None:
        folder[:] = [e for e in folder if e.get("url") != url]


def _promote_bookmark(config, live, d):
    tree = config.setdefault("bookmarks", [])
    if d.change == "added":
        _insert_bookmark(tree, live, d.live["path"], d.live["url"], d.live["name"])
    elif d.change == "removed":
        _remove_bookmark(tree, d.config["path"], d.config["url"])
    elif d.change == "renamed":
        for e in _folder(tree, d.live["path"], False) or []:
            if e.get("url") == d.live["url"]:
                e["name"] = d.live["name"]
    elif d.change == "moved":
        _remove_bookmark(tree, d.config["path"], d.ident)
        _insert_bookmark(tree, live, d.live["path"], d.ident, d.live["name"])
    elif d.change == "reordered":
        folder = _folder(tree, d.extra["path"], False) or []
        slots = [i for i, e in enumerate(folder) if "url" in e]
        rank = {u: i for i, u in enumerate(d.live)}
        items = sorted((folder[i] for i in slots), key=lambda e: rank.get(e["url"], len(rank)))
        for i, e in zip(slots, items):
            folder[i] = e


def _promote_pin(config, d):
    pins = config.setdefault("pins", [])
    spaces = config.setdefault("spaces", [])
    if d.kind == "space":
        spaces[:] = [s for s in spaces if s["id"] != d.ident]
        if d.change != "removed":
            spaces.append(d.live)
        return
    if d.change == "reordered":
        # ponytail: copies live positions as-is; ties with config-only pins keep file order.
        for p in pins:
            p["position"] = d.extra["positions"].get(p["id"], p["position"])
    else:
        pins[:] = [p for p in pins if p["id"] != d.ident]
        if d.change != "removed":
            pins.append(d.live)
    pins.sort(key=lambda p: p.get("position", 1000))


def _flake_shortcut(entry):
    mods = entry.get("modifiers") or {}
    return {"id": entry["id"], "key": entry.get("key"), "keycode": entry.get("keycode"),
            "modifiers": {m: bool(mods.get(m)) for m in MODIFIERS}, "disabled": bool(entry.get("disabled"))}


def _revert_session(data, pin_ids, space_ids):
    raw_folders = {f["id"] for f in data.get("folders", []) if norm_id(f["id"]) in pin_ids}
    placeholders = {t for f in data.get("folders", []) if f["id"] in raw_folders for t in f.get("emptyTabIds", [])}
    data["folders"] = [f for f in data.get("folders", []) if f["id"] not in raw_folders]
    tabs = []
    for t in data.get("tabs", []):
        sid = t.get("zenSyncId")
        if sid in placeholders:
            continue
        if (t.get("pinned") or t.get("zenEssential")) and sid and norm_id(sid) in pin_ids:
            continue
        if t.get("groupId") in raw_folders:
            t["groupId"] = None
        tabs.append(t)
    data["tabs"] = tabs
    raw_spaces = {s["uuid"] for s in data.get("spaces", []) if norm_id(s["uuid"]) in space_ids}
    if raw_spaces:
        data["spaces"] = [s for s in data["spaces"] if s["uuid"] not in raw_spaces]
        fallback = data["spaces"][0]["uuid"] if data["spaces"] else None
        for t in data["tabs"]:
            if t.get("zenWorkspace") in raw_spaces:
                t["zenWorkspace"] = fallback
    return data


def _unset_override(repo, profile, kind, ident, res):
    rel = f"settings/{profile.key}.json" if kind == "setting" else f"shortcuts/{profile.key}.json"
    if not os.path.exists(repo.path(rel)):
        return
    data = repo.load(rel, {})
    if kind == "setting":
        if ident not in data:
            return
        del data[ident]
    else:
        kept = [e for e in data if e.get("id") != ident]
        if len(kept) == len(data):
            return
        data = kept
    res.written.add(repo.save(rel, data))


def check_repo(repo):
    for pat in ("profiles/*.json", "settings/*.json", "shortcuts/*.json", "toolbar*.json"):
        for p in sorted(glob.glob(repo.path(pat))):
            repo.load(os.path.relpath(p, repo.zen), None)


def apply(profile, repo, actions):
    check_repo(repo)
    res = Result()
    profile_rel = f"profiles/{profile.key}.json"
    config = None
    live_tree = None
    for a in actions:
        d = a.diff
        if a.verb == "ignore":
            ignore = repo.load("settings/ignore.json", {})
            if d.ident not in ignore.setdefault(d.kind, []):
                ignore[d.kind].append(d.ident)
            res.written.add(repo.save("settings/ignore.json", ignore))
        elif a.verb == "promote":
            if d.kind in ("bookmark", "pin", "space"):
                if config is None:
                    config = repo.load(profile_rel, {})
                if d.kind == "bookmark":
                    if d.ident == "adopt":
                        config["bookmarks"] = d.live
                    else:
                        if live_tree is None:
                            live_tree = read_bookmarks(profile.file("places.sqlite"))
                        _promote_bookmark(config, live_tree, d)
                else:
                    _promote_pin(config, d)
            elif d.kind == "toolbar":
                own = f"toolbar-{profile.key}.json"
                rel = own if a.target == "profile" else "toolbar.json"
                data = repo.load(repo.toolbar_file(profile.key) if a.target == "profile" else rel, {})
                data.setdefault("placements", {})[d.ident] = d.live
                res.written.add(repo.save(rel, data))
            elif d.kind == "setting":
                rel = "settings/shared.json" if a.target == "shared" else f"settings/{profile.key}.json"
                data = repo.load(rel, {})
                data[d.ident] = d.live
                res.written.add(repo.save(rel, data))
                if a.target == "shared":
                    _unset_override(repo, profile, "setting", d.ident, res)
            elif d.kind == "shortcut":
                rel = "shortcuts/shared.json" if a.target == "shared" else f"shortcuts/{profile.key}.json"
                live = read_shortcuts(profile.file("zen-keyboard-shortcuts.json"))[d.ident]
                data = [e for e in repo.load(rel, []) if e.get("id") != d.ident] + [_flake_shortcut(live)]
                res.written.add(repo.save(rel, data))
                if a.target == "shared":
                    _unset_override(repo, profile, "shortcut", d.ident, res)
                with open(profile.file(BASELINE)) as f:
                    base = json.load(f)
                base["shortcuts"] = [live if e.get("id") == d.ident else e for e in base["shortcuts"]]
                with open(profile.file(BASELINE), "w") as f:
                    json.dump(base, f)
        elif d.revert == "none":
            continue
        elif d.revert == "restart":
            res.restart.append(d)
        elif d.revert == "switch":
            res.switch.append(d)
        else:
            res.queued.append(d)
    if config is not None:
        res.written.add(repo.save(profile_rel, config))
    if res.queued and not zen_running(profile.dir):
        _apply_edits(profile, res.queued)
        res.reverted, res.queued = res.queued, []
    return res


def _apply_edits(profile, diffs):
    prefs = {d.ident for d in diffs if d.kind == "setting"}
    if prefs:
        remove_prefs(profile.file("prefs.js"), prefs)
    pin_ids = {d.ident for d in diffs if d.kind == "pin"}
    space_ids = {d.ident for d in diffs if d.kind == "space"}
    if pin_ids or space_ids:
        path = profile.file("zen-sessions.jsonlz4")
        save_session(path, _revert_session(load_session(path), pin_ids, space_ids))
    shortcuts = {d.ident for d in diffs if d.kind == "shortcut"}
    if shortcuts:
        path = profile.file("zen-keyboard-shortcuts.json")
        base = read_baseline(profile.file(BASELINE))
        with open(path) as f:
            data = json.load(f)
        backup(path)
        for e in data["shortcuts"]:
            if e.get("id") in shortcuts:
                for k in ("key", "keycode", "modifiers", "disabled"):
                    e[k] = base[e["id"]].get(k)
        with open(path, "w") as f:
            json.dump(data, f)


def summary(res):
    lines = []
    if res.written:
        lines += ["Repo files written:"] + [f"  home/programs/zen/{r}" for r in sorted(res.written)]
        lines += ["Next: git add, git diff, commit, then nixswitch."]
    if res.reverted:
        lines.append(f"Reverted now: {len(res.reverted)}")
    if res.restart:
        lines.append(f"Revert on the next Zen start: {len(res.restart)}")
    if res.switch:
        lines.append(f"Revert on the next switch: {len(res.switch)}")
    if res.queued:
        lines.append(f"Queued (still marked), close Zen and apply again: {len(res.queued)}")
    return "\n".join(lines) or "Nothing to do."
