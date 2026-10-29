#!/usr/bin/python3
import fcntl
import os
import re
import subprocess
import sys

import gi

gi.require_version("Gdk", "3.0")
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gdk, Gtk, GtkLayerShell, Pango

THUMBS = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "cliphist", "thumbs")
LOCK = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "clipboard-picker.lock")
IMAGE = re.compile(r"^\[\[ binary data (.+) ([a-z]+) (\d+)x(\d+) \]\]$")
WIDTH = 400
THUMB_W = 336
THUMB_H = 180
THUMB_MIN_H = 48
THUMB_RADIUS = 8

CSS = b"""
* {
    font-family: "JetBrains Mono Nerd Font";
    font-size: 10pt;
    color: #C0CAF5;
}
window {
    background-color: transparent;
}
.main {
    background-color: #15161E;
    border-radius: 8px;
    padding: 16px;
}
entry {
    background: transparent;
    border: none;
    box-shadow: none;
    padding: 0;
    min-height: 0;
    caret-color: #C0CAF5;
}
list {
    background: transparent;
}
row {
    padding: 8px;
    margin-bottom: 5px;
    border-radius: 4px;
    background: transparent;
    outline: none;
}
row:hover {
    background-color: #1A1B26;
}
row:selected {
    background-color: #C0CAF5;
}
row:selected label {
    color: #15161E;
}
scrolledwindow undershoot, scrolledwindow overshoot {
    background: none;
    box-shadow: none;
}
scrollbar {
    background: transparent;
    border: none;
    margin-left: 10px;
}
scrollbar trough {
    background-color: #1A1B26;
    border-radius: 8px;
    min-width: 5px;
}
scrollbar slider {
    min-width: 5px;
    min-height: 24px;
    margin: 0;
    border: none;
    border-radius: 8px;
    background-color: #C0CAF5;
}
scrollbar button {
    min-width: 0;
    min-height: 0;
    padding: 0;
    border: none;
    background: none;
}
"""


def entries():
    out = subprocess.run(["cliphist", "list"], capture_output=True, text=True, errors="replace").stdout
    for line in out.splitlines():
        id_, _, preview = line.partition("\t")
        if id_.isdigit():
            yield id_, preview


def thumbnail(id_, match):
    path = os.path.join(THUMBS, f"{id_}-{match[3]}x{match[4]}-{match[1].replace(' ', '')}-{THUMB_W}x{THUMB_H}.png")
    if os.path.exists(path):
        return path
    w, h = int(match[3]), int(match[4])
    height = max(round(h * min(THUMB_W / w, THUMB_H / h, 1)), THUMB_MIN_H)
    size = f"{THUMB_W}x{height}"
    data = subprocess.run(["cliphist", "decode", id_], capture_output=True).stdout
    result = subprocess.run(
        [
            "magick", "-", "-auto-orient",
            "(", "-clone", "0", "-background", "#15161E", "-alpha", "remove", "-resize", f"{size}^", "-gravity", "center", "-extent", size,
            "-blur", "0x10", "-fill", "#15161E", "-colorize", "40%", ")",
            "(", "-clone", "0", "-resize", f"{size}>", ")",
            "-delete", "0", "-gravity", "center", "-compose", "over", "-composite", "-alpha", "set",
            "(", "-size", size, "xc:none", "-fill", "white",
            "-draw", f"roundrectangle 0,0 {THUMB_W - 1},{height - 1} {THUMB_RADIUS},{THUMB_RADIUS}", ")",
            "-compose", "DstIn", "-composite", f"png:{path}",
        ],
        input=data,
        capture_output=True,
    )
    return path if result.returncode == 0 and os.path.exists(path) else None


class Picker(Gtk.Window):
    def __init__(self):
        super().__init__()
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_namespace(self, "clipboard")
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.EXCLUSIVE)
        GtkLayerShell.set_exclusive_zone(self, -1)
        for edge in (GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM, GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.RIGHT):
            GtkLayerShell.set_anchor(self, edge, True)
        self.set_visual(self.get_screen().get_rgba_visual())

        self.main = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10, halign=Gtk.Align.CENTER, valign=Gtk.Align.CENTER)
        self.main.set_size_request(WIDTH, -1)
        self.main.get_style_context().add_class("main")
        self.add(self.main)

        bar = Gtk.Box(spacing=10)
        bar.pack_start(Gtk.Label(label=""), False, False, 0)
        self.search = Gtk.Entry(hexpand=True)
        self.search.connect("changed", self.on_search)
        self.placeholder = Gtk.Label(label="search...", xalign=0)
        field = Gtk.Overlay()
        field.add(self.search)
        field.add_overlay(self.placeholder)
        field.set_overlay_pass_through(self.placeholder, True)
        bar.pack_start(field, True, True, 0)
        self.main.pack_start(bar, False, False, 0)

        self.list = Gtk.ListBox(selection_mode=Gtk.SelectionMode.SINGLE)
        self.list.set_filter_func(self.matches)
        self.list.connect("row-activated", lambda _, row: self.copy(row))
        self.scroll = Gtk.ScrolledWindow(
            hscrollbar_policy=Gtk.PolicyType.NEVER,
            propagate_natural_height=True,
            max_content_height=560,
        )
        self.scroll.set_overlay_scrolling(False)
        self.scroll.connect("scroll-event", self.on_scroll)
        self.anim = None
        self.scroll.add(self.list)
        self.main.pack_start(self.scroll, True, True, 0)

        self.rows = []
        os.makedirs(THUMBS, exist_ok=True)
        keep = set()
        for id_, preview in entries():
            row = Gtk.ListBoxRow()
            row.id = id_
            row.text = preview.lower()
            row.thumb = None
            match = IMAGE.match(preview)
            path = thumbnail(id_, match) if match else None
            if path:
                row.thumb = path
                keep.add(os.path.basename(path))
                row.add(Gtk.Image(file=path, halign=Gtk.Align.CENTER))
            else:
                row.add(Gtk.Label(label=preview, xalign=0, ellipsize=Pango.EllipsizeMode.END))
            self.list.add(row)
            self.rows.append(row)
        for name in os.listdir(THUMBS):
            if name not in keep:
                os.remove(os.path.join(THUMBS, name))

        self.connect("key-press-event", self.on_key)
        self.connect("button-press-event", self.on_click)
        self.connect("destroy", Gtk.main_quit)
        self.show_all()
        self.search.grab_focus()
        self.select(next(iter(self.rows), None))

    def matches(self, row):
        return all(word in row.text for word in self.search.get_text().lower().split())

    def visible(self):
        return [row for row in self.rows if self.matches(row)]

    def select(self, row):
        if row:
            self.list.select_row(row)
        else:
            self.list.unselect_all()

    def reveal(self, row):
        alloc = row.get_allocation()
        page = self.scroll.get_vadjustment().get_page_size()
        base = self.target()
        if alloc.y < base:
            self.scroll_to(alloc.y)
        elif alloc.y + alloc.height > base + page:
            self.scroll_to(alloc.y + alloc.height - page)

    def target(self):
        return self.anim[1] if self.anim else self.scroll.get_vadjustment().get_value()

    def scroll_to(self, value):
        adj = self.scroll.get_vadjustment()
        value = max(adj.get_lower(), min(value, adj.get_upper() - adj.get_page_size()))
        clock = self.scroll.get_frame_clock()
        if not clock:
            adj.set_value(value)
            return
        if not self.anim:
            self.scroll.add_tick_callback(self.tick)
        self.anim = (adj.get_value(), value, clock.get_frame_time())

    def tick(self, _, clock):
        if not self.anim:
            return False
        start, end, began = self.anim
        t = min((clock.get_frame_time() - began) / 180000, 1)
        self.scroll.get_vadjustment().set_value(start + (end - start) * (1 - (1 - t) ** 3))
        if t < 1:
            return True
        self.anim = None
        return False

    def on_scroll(self, _, event):
        device = event.get_source_device()
        if device and device.get_source() == Gdk.InputSource.TOUCHPAD:
            return False
        ok, _, dy = event.get_scroll_deltas()
        if not ok:
            dy = {Gdk.ScrollDirection.UP: -1, Gdk.ScrollDirection.DOWN: 1}.get(event.direction, 0)
        if not dy:
            return False
        self.scroll_to(self.target() + dy * self.scroll.get_vadjustment().get_page_size() ** (2 / 3))
        return True

    def move(self, step):
        rows = self.visible()
        if not rows:
            return
        current = self.list.get_selected_row()
        index = rows.index(current) if current in rows else -1
        row = rows[(index + step) % len(rows)]
        self.select(row)
        self.reveal(row)

    def on_search(self, _):
        self.placeholder.set_visible(not self.search.get_text())
        self.list.invalidate_filter()
        self.anim = None
        self.scroll.get_vadjustment().set_value(0)
        self.select(next(iter(self.visible()), None))

    def on_key(self, _, event):
        key = event.keyval
        shift = event.state & Gdk.ModifierType.SHIFT_MASK
        row = self.list.get_selected_row()
        if key == Gdk.KEY_Escape:
            self.destroy()
        elif key in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            if row:
                self.copy(row)
        elif key == Gdk.KEY_Down:
            self.move(1)
        elif key == Gdk.KEY_Up:
            self.move(-1)
        elif key == Gdk.KEY_Delete and shift:
            self.wipe()
        elif key == Gdk.KEY_Delete:
            if row:
                self.delete(row)
        else:
            return False
        return True

    def on_click(self, _, event):
        if event.window != self.get_window():
            return False
        alloc = self.main.get_allocation()
        inside = alloc.x <= event.x < alloc.x + alloc.width and alloc.y <= event.y < alloc.y + alloc.height
        if not inside:
            self.destroy()
        return not inside

    def copy(self, row):
        decode = subprocess.Popen(["cliphist", "decode", row.id], stdout=subprocess.PIPE)
        subprocess.run(["wl-copy"], stdin=decode.stdout, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        decode.wait()
        self.destroy()

    def delete(self, row):
        if subprocess.run(["cliphist", "delete"], input=row.id.encode()).returncode:
            return
        rows = self.visible()
        index = rows.index(row)
        if row.thumb and os.path.exists(row.thumb):
            os.remove(row.thumb)
        self.rows.remove(row)
        self.list.remove(row)
        rows.remove(row)
        if not self.rows:
            self.destroy()
            return
        self.select(rows[min(index, len(rows) - 1)] if rows else None)

    def wipe(self):
        config = subprocess.run(["cliphist", "version"], capture_output=True, text=True).stderr
        db = dict(line.split("\t", 1) for line in config.splitlines() if "\t" in line).get("db-path")
        if not db:
            return
        if os.path.exists(db):
            os.remove(db)
        for name in os.listdir(THUMBS):
            os.remove(os.path.join(THUMBS, name))
        self.destroy()


def main():
    lock = open(LOCK, "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        sys.exit()
    provider = Gtk.CssProvider()
    provider.load_from_data(CSS)
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER)
    Picker()
    Gtk.main()


if __name__ == "__main__":
    main()
