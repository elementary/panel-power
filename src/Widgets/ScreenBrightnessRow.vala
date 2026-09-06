/*
 * Copyright 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Authored by: Denis Garaev <garaevdi@outlook.com>
 */

public class Power.Widgets.ScreenBrightenssRow : Granite.Bin {
    private Services.BrightnessManager brightness_manager;

    public int index { get; construct; }

    public bool natural_scroll_touchpad { get; set; }
    public bool natural_scroll_mouse { get; set; }

    public ScreenBrightenssRow (int index) {
        Object (index: index);
    }

    construct {
        brightness_manager = Services.BrightnessManager.get_default ();

        var mouse_settings = new GLib.Settings ("org.gnome.desktop.peripherals.mouse");
        mouse_settings.bind ("natural-scroll", this, "natural-scroll-mouse", SettingsBindFlags.DEFAULT);
        var touchpad_settings = new GLib.Settings ("org.gnome.desktop.peripherals.touchpad");
        touchpad_settings.bind ("natural-scroll", this, "natural-scroll-touchpad", SettingsBindFlags.DEFAULT);

        var scroll_controller = new Gtk.EventControllerScroll (BOTH_AXES);
        scroll_controller.scroll.connect (on_scroll);
        add_controller (scroll_controller);

        var image = new Gtk.Image.from_icon_name ("brightness-display-symbolic") {
            pixel_size = 48
        };

        var monitor_label = new Gtk.Label (brightness_manager.get_monitor_name (index)) {
            halign = Gtk.Align.START
        };

        if (index == 0) {
            monitor_label.set_text (monitor_label.get_text () + _(" (Primary)"));
        }

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

        child = box;

        ulong slider_signal = 0, dm_signal = 0;
        slider_signal = brightness_slider.value_changed.connect ((value) => {
            SignalHandler.block (brightness_manager, dm_signal);
            brightness_manager.set_monitor_brightness (index, value.get_value ());
            SignalHandler.unblock (brightness_manager, dm_signal);
        });
        dm_signal = brightness_manager.monitor_brightness_changed.connect ((ch_index, value) => {
            if (index != ch_index) {
                return;
            }

            SignalHandler.block (brightness_slider, slider_signal);
            brightness_slider.set_value (value);
            SignalHandler.unblock (brightness_slider, slider_signal);
        });

        brightness_slider.set_value (brightness_manager.get_monitor_brightness (index));
    }

    private bool on_scroll (Gtk.EventControllerScroll controller, double dx, double dy) {
        return Utils.handle_local_scroll_event ((Gdk.ScrollEvent) controller.get_current_event (), natural_scroll_mouse, natural_scroll_touchpad, index);
    }
}
