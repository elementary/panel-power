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

public class Power.Widgets.ScreenBrightness : Granite.Bin {
    private Power.Services.DeviceManager dm;
    private Gtk.ListBox list_box;

    public bool natural_scroll_touchpad { get; set; }
    public bool natural_scroll_mouse { get; set; }

    construct {
        dm = Power.Services.DeviceManager.get_default ();

        var mouse_settings = new GLib.Settings ("org.gnome.desktop.peripherals.mouse");
        mouse_settings.bind ("natural-scroll", this, "natural-scroll-mouse", SettingsBindFlags.DEFAULT);
        var touchpad_settings = new GLib.Settings ("org.gnome.desktop.peripherals.touchpad");
        touchpad_settings.bind ("natural-scroll", this, "natural-scroll-touchpad", SettingsBindFlags.DEFAULT);

        var scroll_controller = new Gtk.EventControllerScroll (BOTH_AXES);
        scroll_controller.scroll.connect (on_scroll);
        add_controller (scroll_controller);

        list_box = new Gtk.ListBox ();
        child = list_box;

        populate_list ();

        dm.monitors_changed.connect (() => {
            list_box.remove_all ();
            populate_list ();
        });
    }

    private void populate_list () {
        for (int i = 0; i < dm.get_monitor_count (); i++) {
            list_box.append (construct_row (i));
        }
    }

    private Gtk.Widget construct_row (int index) {
        var image = new Gtk.Image.from_icon_name ("brightness-display-symbolic") {
            pixel_size = 48
        };

        var monitor_label = new Gtk.Label (dm.get_monitor_data (index)) {
            halign = Gtk.Align.START
        };

        var brightness_slider = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 1, 0.1) {
            margin_start = 2,
            margin_end = 2,
            hexpand = true,
            draw_value = false,
            width_request = 175
        };

        var slider_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2) {
            hexpand = true,
            vexpand = true,
            homogeneous = true
        };

        slider_box.append (monitor_label);
        slider_box.append (brightness_slider);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4) {
            hexpand = true,
            margin_start = 6,
            margin_end = 12
        };

        box.append (image);
        box.append (slider_box);

        ulong slider_signal = 0, dm_signal = 0;
        slider_signal = brightness_slider.value_changed.connect ((value) => {
            SignalHandler.block (dm, dm_signal);
            dm.set_monitor_brightness (index, value.get_value ());
            SignalHandler.unblock (dm, dm_signal);
        });
        dm_signal = dm.monitor_brightness_changed.connect ((ch_index, value) => {
            if (index != ch_index) {
                return;
            }

            SignalHandler.block (brightness_slider, slider_signal);
            brightness_slider.set_value (value);
            SignalHandler.unblock (brightness_slider, slider_signal);
        });

        brightness_slider.set_value (dm.get_monitor_brightness (index));
        return box;
    }

    private bool on_scroll (Gtk.EventControllerScroll controller, double dx, double dy) {
        return Utils.handle_scroll_event ((Gdk.ScrollEvent) controller.get_current_event (), natural_scroll_mouse, natural_scroll_touchpad);
    }
}
