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

public class Power.Indicator : Wingpanel.Indicator {
    private const double LOW_BATTERY_PERCENTAGE = 20.0;

    public bool is_in_session { get; construct; default = false; }
    public bool natural_scroll_touchpad { get; set; }
    public bool natural_scroll_mouse { get; set; }

    private Widgets.DisplayWidget? display_widget = null;

    private Widgets.PopoverWidget? popover_widget = null;

    private Services.Device? display_device = null;
    private Services.DeviceManager dm;

    private Settings settings;

    public Indicator (bool is_in_session) {
        Object (
            code_name : Wingpanel.Indicator.POWER,
            is_in_session: is_in_session
        );
    }

    construct {
        GLib.Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
        Gtk.IconTheme.get_for_display (Gdk.Display.get_default ()).add_resource_path ("/io/elementary/panel/power");

        dm = Power.Services.DeviceManager.get_default ();

        var mouse_settings = new GLib.Settings ("org.gnome.desktop.peripherals.mouse");
        mouse_settings.bind ("natural-scroll", this, "natural-scroll-mouse", SettingsBindFlags.DEFAULT);
        var touchpad_settings = new GLib.Settings ("org.gnome.desktop.peripherals.touchpad");
        touchpad_settings.bind ("natural-scroll", this, "natural-scroll-touchpad", SettingsBindFlags.DEFAULT);

        settings = new GLib.Settings ("io.elementary.panel.power");
    }

    public override Gtk.Widget get_display_widget () {
        if (display_widget == null) {
            display_widget = new Widgets.DisplayWidget ();

            /* No need to display the indicator when the device is completely in AC mode */
            if (dm.has_battery || dm.backlight.present) {
                update_visibility ();
            }

            dm.notify["has-battery"].connect (update_visibility);
            dm.notify["display-device"].connect (update_display_device);
            settings.changed["show-percentage"].connect (update_tooltip);

            if (dm.backlight.present) {
                var scroll_controller = new Gtk.EventControllerScroll (BOTH_AXES);
                scroll_controller.scroll.connect ((controller, dx, dy) => {
                    if (Utils.handle_scroll_event (
                            (Gdk.ScrollEvent) controller.get_current_event (),
                            natural_scroll_mouse,
                            natural_scroll_touchpad)
                    ) {
                        if (popover_widget == null || !popover_widget.is_visible ()) {
                          show_notification ();
                        }

                        return true;
                    }

                    return false;
                });
                display_widget.add_controller (scroll_controller);

                dm.brightness_changed.connect (update_tooltip);
            }
        }

        return display_widget;
    }

    public override Gtk.Widget? get_widget () {
        if (popover_widget == null) {
            popover_widget = new Widgets.PopoverWidget (is_in_session);
        }

        return popover_widget;
    }

    public override void opened () { }

    public override void closed () {

    }

    private void update_visibility () {
        var dm = Services.DeviceManager.get_default ();

        bool should_be_visible = (dm.has_battery || dm.backlight.present);
        if (visible != should_be_visible) {
            /* NOTE: popover closes every time you set visibility, so change property only when needed */
            visible = should_be_visible;
        }

        if (visible) {
            if (dm.has_battery) {
                update_display_device ();
            } else {
                show_backlight_data ();
            }
        }

        update_tooltip ();
    }

    private void update_display_device () {
        if (display_device != null) {
            display_device.properties_updated.disconnect (show_display_device_data);
        }

        display_device = Services.DeviceManager.get_default ().display_device;
        if (display_device != null) {
            show_display_device_data ();
            display_device.properties_updated.connect (show_display_device_data);
        }

        update_tooltip ();
    }

    private void show_display_device_data () {
        if (display_device != null && display_widget != null) {
            var icon_name = display_device.get_symbolic_icon_name_for_battery ();
            display_widget.icon_name = icon_name;

            /* Debug output for designers */
            debug ("Icon changed to \"%s\"", icon_name);

            if (display_device.percentage <= 0) {
                display_widget.allow_percent = false;
            } else {
                display_widget.percentage = (int) Math.round (display_device.percentage);
                display_widget.allow_percent = true;
            }

            update_tooltip ();
        }
    }

    private void show_backlight_data () {
        if (display_widget != null) {
            display_widget.icon_name = "display-brightness-symbolic";
            display_widget.allow_percent = false;
        }
    }

    private void update_tooltip () {
        string? primary_text = null;
        string? secondary_text = null;
        if (display_device != null) {
            if (display_device.percentage <= LOW_BATTERY_PERCENTAGE && !display_device.is_charging) {
                display_widget.show_percentage (true);
            }

            /* Hide low battery percentage after plug charger if user is not showing percentage */
            var is_showing_percent = settings.get_boolean ("show-percentage");
            if (display_device.is_charging && !is_showing_percent) {
                display_widget.show_percentage (false);
            }
            if (display_device.is_a_battery) {
                primary_text = _("%s: %s").printf (display_device.device_type.get_name (), display_device.description);
                secondary_text = is_showing_percent ? _("Middle-click to hide percentage") : _("Middle-click to show percentage");

            } else {
                primary_text = display_device.device_type.get_name ();
            }
        }

        if (primary_text == null && dm.backlight.present) {
            primary_text = _("Screen brightness: %i").printf ((int)(dm.brightness));
            secondary_text = _("Scroll to change screen brightness");
        }

        if (primary_text == null) {
            display_widget.tooltip_markup = null;
        } else if (secondary_text == null) {
            display_widget.tooltip_markup = primary_text;
        } else {
            display_widget.tooltip_markup = "%s\n%s".printf (
                primary_text,
                Granite.TOOLTIP_SECONDARY_TEXT_MARKUP.printf (secondary_text)
            );
        }
    }

    private bool show_notification () {
        if (is_in_session) {
            var notification = new Notify.Notification ("indicator-power", "", "display-brightness-symbolic");
            notification.set_hint ("x-canonical-private-synchronous", new Variant.string ("indicator-power"));
            notification.set_hint ("value", new Variant.int32 (dm.brightness));
            try {
                notification.show ();
                return true;
            } catch (Error e) {
                warning ("Unable to show notification: %s", e.message);
            }

        }

        return false;
    }
}

public Wingpanel.Indicator get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    debug ("Activating Power Indicator");

    var indicator = new Power.Indicator (server_type == Wingpanel.IndicatorManager.ServerType.SESSION);

    return indicator;
}
