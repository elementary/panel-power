/*
 * Copyright 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Power.Widgets.ScreenBrightnessList : Granite.Bin {
    private Power.Services.BrightnessManager brightness_manager;
    private Gtk.ListBox list_box;

    construct {
        brightness_manager = Power.Services.BrightnessManager.get_default ();

        list_box = new Gtk.ListBox () {
            selection_mode = Gtk.SelectionMode.NONE,
            show_separators = true
        };
        child = list_box;

        populate_list ();

        brightness_manager.monitors_changed.connect (populate_list);
    }

    private void populate_list () {
        list_box.remove_all ();
        for (int i = 0; i < brightness_manager.get_n_monitors (); i++) {
            list_box.append (new ScreenBrightnessRow (i));
        }
    }
}
