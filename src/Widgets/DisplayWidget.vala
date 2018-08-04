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

public class Power.Widgets.DisplayWidget : Gtk.Grid {
    private Gtk.Image image;
    private Gtk.Revealer percent_revealer;
    private Gtk.Label percent_label;
    private bool allow_percent = false;
    private GLib.Settings settings;

    construct {
        valign = Gtk.Align.CENTER;

        image = new Gtk.Image ();
        image.icon_name = "content-loading-symbolic";
        image.pixel_size = 24;

        percent_label = new Gtk.Label ("");
        percent_label.margin_start = 6;

        percent_revealer = new Gtk.Revealer ();
        update_revealer ();
        percent_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        percent_revealer.add (percent_label);

        add (image);
        add (percent_revealer);

        settings = new GLib.Settings ("io.elementary.desktop.wingpanel.power");
        settings.changed.connect (update_revealer);

        this.button_press_event.connect ((e) => {
            if (allow_percent && e.button == Gdk.BUTTON_MIDDLE) {
                settings.set_boolean ("show-percentage", !(settings.get_boolean ("show-percentage")));
                return true;
            }
            return false;
        });
    }

    public void set_icon_name (string icon_name, bool allow_percent) {
        image.icon_name = icon_name;
        
        if (this.allow_percent != allow_percent) {
            this.allow_percent = allow_percent;
            update_revealer ();
        }
    }

    public void set_percent (int percentage) {
        percent_label.set_label ("%i%%".printf (percentage));
    }

    private void update_revealer () {
        percent_revealer.reveal_child = settings.get_boolean ("show-percentage") && allow_percent;
    }
}
