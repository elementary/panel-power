/*
 * Copyright 2011-2020 elementary, Inc. (https://elementary.io)
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

public class Power.Widgets.PopoverWidget : Gtk.Box {
    public bool is_in_session { get; construct; default = false; }

    private static Services.DeviceManager dm;

    private Gtk.Revealer device_separator_revealer;

    private PowerModeList power_mode_list;

    public PopoverWidget (bool is_in_session) {
        Object (is_in_session: is_in_session);
    }

    static construct {
        dm = Services.DeviceManager.get_default ();
    }

    construct {
        var settings = new GLib.Settings ("io.elementary.panel.power");

        var device_list = new DeviceList ();

        var device_list_revealer = new Gtk.Revealer () {
            child = device_list,
        };

        var device_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        };

        device_separator_revealer = new Gtk.Revealer () {
            child = device_separator,
        };

        var last_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        };

        var last_separator_revealer = new Gtk.Revealer () {
            reveal_child = dm.brightness != -1,
            child = last_separator,
        };

        var show_percent_switch = new Granite.SwitchModelButton (_("Show Percentage"));
        show_percent_switch.add_css_class (Granite.STYLE_CLASS_H4_LABEL);

        var show_percent_sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        };

        var show_percent_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        show_percent_box.append (show_percent_switch);
        show_percent_box.append (show_percent_sep);

        var show_percent_revealer = new Gtk.Revealer () {
            child = show_percent_box,
        };

        power_mode_list = new PowerModeList ();

        var power_mode_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        };

        var show_settings_button = new Wingpanel.PopoverMenuItem () {
            margin_bottom = 3,
            text = _("Power Settings…")
        };

        orientation = VERTICAL;
        append (show_percent_revealer);
        append (device_list_revealer);
        append (device_separator_revealer);

        if (dm.backlight.present) {
            var screen_brightness = new ScreenBrightness ();
            append (screen_brightness);
        }

        if (PowerModeList.successfully_initialized) {
            append (power_mode_separator);
            append (power_mode_list);
        }

        if (is_in_session) {
            append (last_separator_revealer);
            append (show_settings_button);
        }

        update_device_separator_revealer ();

        dm.notify["has-battery"].connect ((s, p) => {
            update_device_separator_revealer ();
        });

        settings.bind ("show-percentage", show_percent_switch, "active", SettingsBindFlags.DEFAULT);

        dm.bind_property (
            "has-battery",
            device_list_revealer,
            "reveal-child",
            GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE
        );

        if (dm.has_battery && dm.display_device.is_a_battery) {
            show_percent_revealer.reveal_child = true;
        }

        show_settings_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("settings://power", null);
            } catch (Error e) {
                warning ("Failed to open power settings: %s", e.message);
            }
        });

        dm.brightness_changed.connect ((brightness) => {
            if (brightness != -1) {
                last_separator_revealer.reveal_child = true;
            } else {
                last_separator_revealer.reveal_child = false;
            }
        });
    }

    private void update_device_separator_revealer () {
        device_separator_revealer.reveal_child = dm.backlight.present && dm.has_battery;
    }
}
