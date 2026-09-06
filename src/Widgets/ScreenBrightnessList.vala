/*
 * Copyright 2011-2021 elementary, Inc. (https://elementary.io)
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

public class Power.Widgets.ScreenBrightnessList : Granite.Bin {
    private Power.Services.BrightnessManager brightness_manager;
    private Gtk.ListBox list_box;

    public bool natural_scroll_touchpad { get; set; }
    public bool natural_scroll_mouse { get; set; }

    construct {
        brightness_manager = Power.Services.BrightnessManager.get_default ();

        list_box = new Gtk.ListBox ();
        child = list_box;

        populate_list ();

        brightness_manager.monitors_changed.connect (() => {
            list_box.remove_all ();
            populate_list ();
        });
    }

    private void populate_list () {
        for (int i = 0; i < brightness_manager.get_n_monitors (); i++) {
            list_box.append (new ScreenBrightenssRow (i));
        }
    }
}
