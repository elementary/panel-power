/*
 * Copyright (c) 2011-2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

namespace Power.Services.DBusInterfaces {
  [DBus (name = "io.elementary.gala.BrightnessManager")]
  interface BrightnessManager : GLib.Object {
    public signal void monitors_changed ();
    public signal void monitor_brightness_changed (int index, double value);

    public abstract double get_global_brightness () throws GLib.IOError, GLib.DBusError;
    public abstract double get_monitor_brightness (int index) throws GLib.IOError, GLib.DBusError;
    public abstract string get_monitor_name (int index) throws GLib.IOError, GLib.DBusError;
    public abstract int get_n_monitors () throws GLib.IOError, GLib.DBusError;
    public abstract void set_global_brightness (double scale) throws GLib.IOError, GLib.DBusError;
    public abstract void set_monitor_brightness (int index, double brightness) throws GLib.IOError, GLib.DBusError;
  }
}
