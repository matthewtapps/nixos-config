import argparse
import os
import sys

from textual.app import App
from textual.binding import Binding
from textual.screen import ModalScreen
from textual.widgets import DataTable, Footer, Header, Static

import zen_profile as zp

KINDS = [None, "bookmark", "pin", "space", "toolbar", "setting", "shortcut"]
MARKS = {"promote": "P", "revert": "R", "ignore": "I"}


class Confirm(ModalScreen):
    BINDINGS = [Binding("y", "answer(True)", "Yes"), Binding("n", "answer(False)", "No"),
                Binding("escape", "answer(False)", "No")]

    def __init__(self, text):
        super().__init__()
        self.text = text

    def compose(self):
        yield Static(self.text + "\n\n[y] yes   [n] no", id="dialog")

    def action_answer(self, value):
        self.dismiss(value)


class Message(ModalScreen):
    BINDINGS = [Binding("escape", "close", "Close"), Binding("enter", "close", "Close")]

    def __init__(self, text):
        super().__init__()
        self.text = text

    def compose(self):
        yield Static(self.text + "\n\n[enter] close", id="dialog")

    def action_close(self):
        self.dismiss(None)


class ReconcileApp(App):
    CSS = """
    #status { height: 1; }
    #detail { height: 8; border: solid $accent; }
    #dialog { width: 80; height: auto; border: thick $accent; padding: 1 2; background: $surface; }
    Confirm, Message { align: center middle; }
    """
    BINDINGS = [
        Binding("p", "mark('promote')", "Promote"), Binding("r", "mark('revert')", "Revert"),
        Binding("s", "mark('skip')", "Skip"), Binding("i", "mark('ignore')", "Ignore"),
        Binding("t", "target", "Target"), Binding("f", "filter", "Filter"),
        Binding("n", "next_profile", "Profile"), Binding("a", "apply", "Apply"),
        Binding("q", "quit", "Quit"),
    ]

    def __init__(self, repo, profiles, active=None):
        super().__init__()
        self.repo = repo
        self.active = active or repo
        self.profiles = profiles
        self.index = 0
        self.kind = None
        self.diffs = []
        self.notes = []
        self.marks = {}

    def compose(self):
        yield Header()
        self.status = Static(id="status")
        yield self.status
        self.table = DataTable(id="diffs", cursor_type="row")
        yield self.table
        self.detail = Static(id="detail")
        yield self.detail
        yield Footer()

    def on_mount(self):
        # update_cell never widens a column, so an auto-sized empty one stays at 0.
        self.cols = [self.table.add_column("mark", width=4)] + list(
            self.table.add_columns("kind", "change", "item", "revert"))
        self.reload()

    @property
    def profile(self):
        return self.profiles[self.index]

    def reload(self):
        try:
            self.diffs, self.notes = zp.reconcile(self.profile, self.active, self.repo)
        except Exception as e:
            self.diffs, self.notes = [], [f"could not read profile: {e}"]
        self.refresh_table()

    def visible(self):
        return [d for d in self.diffs if self.kind in (None, d.kind)]

    def mark_text(self, d):
        m = self.marks.get((d.kind, d.ident))
        return "" if not m else MARKS[m[0]] + ("*" if m[1] == "profile" else "")

    def refresh_table(self):
        table = self.table
        table.clear()
        for d in self.visible():
            table.add_row(self.mark_text(d), d.kind, self.row_change(d), d.label[:90], d.revert,
                          key=f"{d.kind}\0{d.ident}")
        state = "Zen open" if zp.zen_running(self.profile.dir) else "Zen closed"
        notes = ("  |  " + "; ".join(self.notes)) if self.notes else ""
        self.status.update(
            f"{self.profile.name} ({state})  filter: {self.kind or 'all'}  {len(self.visible())} differences{notes}")
        self.show_detail()

    def row_change(self, d):
        return d.change + (" (pending switch)" if d.extra.get("pending") else "")

    def current(self):
        rows = self.visible()
        row = self.table.cursor_row
        return rows[row] if rows and 0 <= row < len(rows) else None

    def show_detail(self):
        d = self.current()
        text = "" if d is None else (f"live:   {zp.show(d.live)}\nconfig: {zp.show(d.config)}\n"
                                     f"revert: {zp.REVERT_TEXT[d.revert]}")
        self.detail.update(text)

    def on_data_table_row_highlighted(self, event):
        self.show_detail()

    def update_mark(self, d):
        table = self.table
        table.update_cell(f"{d.kind}\0{d.ident}", self.cols[0], self.mark_text(d))

    def action_mark(self, verb):
        d = self.current()
        if d is None:
            return
        if self.repo is None and verb in ("promote", "ignore"):
            return
        key = (d.kind, d.ident)
        if verb == "skip":
            self.marks.pop(key, None)
        else:
            self.marks[key] = (verb, self.marks.get(key, (None, zp.default_target(d)))[1])
        self.update_mark(d)
        table = self.table
        table.move_cursor(row=min(table.cursor_row + 1, len(self.visible()) - 1))

    def action_target(self):
        d = self.current()
        key = d and (d.kind, d.ident)
        if key in self.marks and d.kind in ("setting", "shortcut", "toolbar"):
            verb, target = self.marks[key]
            self.marks[key] = (verb, "profile" if target == "shared" else "shared")
            self.update_mark(d)

    def action_filter(self):
        self.kind = KINDS[(KINDS.index(self.kind) + 1) % len(KINDS)]
        self.refresh_table()

    def action_next_profile(self):
        self.index = (self.index + 1) % len(self.profiles)
        self.marks = {}
        self.kind = None
        self.reload()

    def action_apply(self):
        actions = [zp.Action(d, *self.marks[(d.kind, d.ident)]) for d in self.diffs if (d.kind, d.ident) in self.marks]
        if not actions:
            return

        def done(ok):
            if not ok:
                return
            try:
                res = zp.apply(self.profile, self.repo, actions)
            except ValueError as e:
                self.push_screen(Message(f"Nothing applied: {e}"))
                return
            except OSError as e:
                self.push_screen(Message(f"Apply failed: {e}"))
                return
            self.marks = {(d.kind, d.ident): self.marks[(d.kind, d.ident)] for d in res.queued}
            self.reload()
            self.push_screen(Message(zp.summary(res)))

        self.push_screen(Confirm(f"Apply {len(actions)} actions to {self.profile.name}?"), done)


def main(argv):
    ap = argparse.ArgumentParser(prog="zen-reconcile")
    ap.add_argument("--repo", help="writable checkout; promote and ignore are off without one")
    ap.add_argument("--active", default=os.path.expanduser("~/.config/zen-reconcile/active"),
                    help="the activated generation's zen JSON")
    ap.add_argument("--zen-dir", default=os.path.expanduser("~/.config/zen"))
    ap.add_argument("--profile")
    args = ap.parse_args(argv)
    profiles = zp.discover(args.zen_dir)
    if args.profile:
        profiles = [p for p in profiles if p.name.lower() == args.profile.lower()]
    if not profiles:
        sys.exit(f"no Zen profiles found in {args.zen_dir}")
    checkout = zp.Repo(args.repo) if args.repo and os.path.isdir(zp.Repo(args.repo).zen) else None
    active = zp.Repo.at(args.active) if os.path.isdir(args.active) else checkout
    if active is None:
        sys.exit(f"no activated config at {args.active} and no checkout")
    ReconcileApp(checkout, profiles, active=active).run()


if __name__ == "__main__":
    main(sys.argv[1:])
