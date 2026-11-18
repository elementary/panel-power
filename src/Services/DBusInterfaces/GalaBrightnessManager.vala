/*
 * Copyright 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[DBus (name = "io.elementary.gala.BrightnessManager")]
interface Power.GalaBrightnessManager : GLib.Object {
    public signal void monitors_changed ();
    public signal void monitor_brightness_changed (int index, double value);

    public abstract double get_global_brightness () throws GLib.IOError, GLib.DBusError;
    public abstract double get_monitor_brightness (int index) throws GLib.IOError, GLib.DBusError;
    public abstract string get_monitor_name (int index) throws GLib.IOError, GLib.DBusError;
    public abstract int get_n_monitors () throws GLib.IOError, GLib.DBusError;
    public abstract void set_global_brightness (double scale) throws GLib.IOError, GLib.DBusError;
    public abstract void set_monitor_brightness (int index, double brightness) throws GLib.IOError, GLib.DBusError;
}
