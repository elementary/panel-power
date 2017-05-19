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

public class Power.Widgets.ScreenBrightness : Gtk.Grid {
    private const string DBUS_PATH = "/org/gnome/SettingsDaemon/Power";
    private const string DBUS_NAME = "org.gnome.SettingsDaemon";

    private Gtk.Image image;
    private Gtk.Scale brightness_slider;
    private Services.DBusInterfaces.PowerSettings iscreen;

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        column_spacing = 6;
        init_bus.begin ();

        image = new Gtk.Image.from_icon_name ("brightness-display-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        image.margin_start = 6;
        image.pixel_size = 24;
        attach (image, 0, 0, 1, 1);

        brightness_slider = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 10);
        brightness_slider.margin_end = 12;
        brightness_slider.hexpand = true;
        brightness_slider.draw_value = false;
        brightness_slider.width_request = 175;

        brightness_slider.value_changed.connect (() => {
            on_scale_value_changed.begin ();
        });

      #if OLD_GSD
        brightness_slider.set_value (iscreen.get_percentage ());
      #else
        brightness_slider.set_value (iscreen.brightness);
      #endif

        attach (brightness_slider, 1, 0, 1, 1);
    }

    public void update_slider () {
      #if OLD_GSD
        brightness_slider.set_value (iscreen.get_percentage ());
      #else
        brightness_slider.set_value (iscreen.brightness);
      #endif
    }

    private async void init_bus () {
        try {
            iscreen = Bus.get_proxy_sync (BusType.SESSION, DBUS_NAME, DBUS_PATH, DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
        } catch (IOError e) {
            warning ("screen brightness error %s", e.message);
        }
    }

    private async void on_scale_value_changed () {
        int val = (int) brightness_slider.get_value ();
        try {
          #if OLD_GSD
            if (iscreen.get_percentage () != val) {
                iscreen.set_percentage (val);
            }
          #else
            if (iscreen.brightness != val) {
                iscreen.brightness = val;
            }
          #endif
        } catch (IOError e) {
            warning ("screen brightness error %s", e.message);
        }
    }
}
