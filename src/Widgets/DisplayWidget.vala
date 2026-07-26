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

public class Power.Widgets.DisplayWidget : Gtk.Box {
    private static Settings settings = new GLib.Settings ("io.elementary.panel.power");

    private Gtk.Revealer percent_revealer;
    public string icon_name {
        set {
            image.icon_name = value;
        }
    }

    public bool allow_percent { get; set; default = false; }
    public int percentage {
        set {
            ///Translators: This represents battery charge precentage with `%i` representing the number and `%%` representing the percent symbol
            percent_label.label = _("%i%%").printf (value);
        }
    }

    private Gtk.Label percent_label;
    private Gtk.Image image;

    construct {
        valign = Gtk.Align.CENTER;

        image = new Gtk.Image () {
            icon_name = "content-loading-symbolic",
            pixel_size = 24
        };

        percent_label = new Gtk.Label (null);

        percent_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            child = percent_label,
        };

        append (image);
        append (percent_revealer);

        settings.bind ("show-percentage", percent_revealer, "reveal-child", GLib.SettingsBindFlags.GET);
        bind_property ("allow-percent", percent_revealer, "visible", GLib.BindingFlags.SYNC_CREATE);

        var gesture_click = new Gtk.GestureClick () {
            button = Gdk.BUTTON_MIDDLE
        };
        gesture_click.pressed.connect (on_press);
        add_controller (gesture_click);
    }

    public void show_percentage (bool show) {
        percent_revealer.reveal_child = show;
    }

    private void on_press () {
        if (allow_percent) {
            settings.set_boolean ("show-percentage", !(settings.get_boolean ("show-percentage")));
        }
    }
}
