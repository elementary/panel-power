/*
 * Copyright (c) 2011-2016 elementary LLC. (https://elementary.io)
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
  [DBus (name = "org.gnome.SettingsDaemon.Power.Screen")]
  interface PowerSettings : GLib.Object {
    #if OLD_GSD
    public abstract uint get_percentage () throws IOError;
    public abstract uint set_percentage (uint percentage) throws IOError;
    #else
    // use the Brightness property after updateing g-s-d to 3.10 or above
    public abstract int brightness { get; set; }
    #endif
  }
}
