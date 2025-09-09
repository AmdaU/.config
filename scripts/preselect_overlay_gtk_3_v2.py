#!/usr/bin/env python3
import json
import subprocess
import sys

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, Gdk, GLib, cairo, GtkLayerShell

# Appearance
GHOST_FILL = (0.15, 0.55, 1.0, 0.22)   # RGBA fill for ghost region
GHOST_BORDER = (0.15, 0.55, 1.0, 0.9)  # RGBA border
BORDER_WIDTH = 3.0
VEIL = (0.0, 0.0, 0.0, 0.08)           # subtle dim; set alpha 0.0 to disable

# Behavior
DURATION_MS = 1000
SPLIT_RATIO = 0.5  # 50/50; change to your default split ratio (0.5..0.9)
BAR_OFFSET = 50
GAPS_OUT = 10
GAPS_IN = 2

# Who gets the new container? Here we assume the NEW container goes
# into the side toward which you preselect (bspwm-like).
NEW_ON_PRESELECT_SIDE = True

def hypr_json(cmd):
    out = subprocess.check_output(["hyprctl", "-j"] + cmd.split(), text=True)
    return json.loads(out)

def get_active_window_and_monitor():
    data = hypr_json("activewindow")
    if not data or "at" not in data or "size" not in data:
        return None
    x, y = data["at"]
    w, h = data["size"]

    mons = hypr_json("monitors")
    mon_rect = None
    mon_id = data.get("monitor", -1)
    for m in mons:
        if m.get("id") == mon_id or m.get("name") == data.get("monitor"):
            mon_rect = (m["x"], m["y"], m["width"], m["height"], m.get("scale", 1.0))
            break
    return {"win": (x, y, w, h), "mon": mon_rect}

def compute_ghost_rect(focus_rect, dir_char, ratio=SPLIT_RATIO):
    x, y, w, h = focus_rect
    # Determine which side will show the "new" window
    # If NEW_ON_PRESELECT_SIDE is False, invert the chosen half.
    if dir_char == "l":
        if NEW_ON_PRESELECT_SIDE:
            return (x, y, int(w * ratio), h)
        else:
            # old on left, new on right
            return (x + int(w * ratio), y, w - int(w * ratio), h)
    elif dir_char == "r":
        if NEW_ON_PRESELECT_SIDE:
            return (x + (w - int(w * ratio)), y, int(w * ratio), h)
        else:
            return (x, y, w - int(w * ratio), h)
    elif dir_char == "u":
        if NEW_ON_PRESELECT_SIDE:
            return (x, y, w, int(h * ratio))
        else:
            return (x, y + int(h * ratio), w, h - int(h * ratio))
    else:  # "d"
        if NEW_ON_PRESELECT_SIDE:
            return (x, y + (h - int(h * ratio)), w, int(h * ratio))
        else:
            return (x, y, w, h - int(h * ratio))

def dispatch_preselect(direction):
    subprocess.call(["hyprctl", "dispatch", "layoutmsg", f"preselect {direction}"])

class Overlay(Gtk.Window):
    def __init__(self, direction):

        Gtk.Window.__init__(self, type=Gtk.WindowType.TOPLEVEL)
        self.direction = direction

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.NONE)
        GtkLayerShell.auto_exclusive_zone_enable(self)

        rects = get_active_window_and_monitor()
        self.rects = rects

        if rects and rects["mon"]:
            mon_x, mon_y, width, height, scale = rects["mon"]
        else:
            disp = Gdk.Display.get_default()
            scr = disp.get_default_screen()
            width = scr.get_width()
            height = scr.get_height()

        self.set_default_size(width, height)

        area = Gtk.DrawingArea()
        area.connect("draw", self.on_draw)
        self.add(area)

        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.LEFT, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, True)

        GLib.timeout_add(DURATION_MS, self.on_timeout)

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual is not None:
            self.set_visual(visual)
        self.set_app_paintable(True)

    def on_draw(self, area, cr):
        # Veil
        cr.set_source_rgba(*VEIL)
        cr.paint()

        if not self.rects or not self.rects["win"] or not self.rects["mon"]:
            return False

        win_x, win_y, win_w, win_h = self.rects["win"]
        mon_x, mon_y, mw, mh, scale = self.rects["mon"]

        # Convert global to monitor-local coordinates
        lx = win_x - mon_x
        ly = win_y - mon_y

        gx, gy, gw, gh = compute_ghost_rect((lx, ly, win_w, win_h), self.direction)

        gy -= BAR_OFFSET + GAPS_OUT + BORDER_WIDTH

        # Fill
        cr.set_source_rgba(*GHOST_FILL)
        cr.rectangle(gx, gy, gw, gh)
        cr.fill_preserve()

        # Border
        cr.set_source_rgba(*GHOST_BORDER)
        cr.set_line_width(BORDER_WIDTH)
        cr.stroke()

        return False

    def on_timeout(self):
        self.destroy()
        Gtk.main_quit()
        return False

def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("l", "r", "u", "d"):
        print("Usage: preselect_ghost_gtk3.py [l|r|u|d]", file=sys.stderr)
        sys.exit(2)
    direction = sys.argv[1]

    # Set preselect immediately (so your layout is primed)
    dispatch_preselect(direction)

    win = Overlay(direction)
    win.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
