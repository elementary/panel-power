/*
 * Copyright 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Authored by: Denis Garaev <garaevdi@outlook.com>
 */

public class Power.Widgets.ScreenBrightnessRow : Granite.Bin {
    private Services.BrightnessManager brightness_manager;
    private Gtk.Scale brightness_slider;
    private ulong slider_signal;
    private ulong bm_signal;

    public int index { get; construct; }

    public ScreenBrightnessRow (int index) {
        Object (index: index);
    }

    construct {
        brightness_manager = Services.BrightnessManager.get_default ();

        var scroll_controller = new Gtk.EventControllerScroll (BOTH_AXES);
        scroll_controller.scroll.connect (on_scroll);
        add_controller (scroll_controller);

        var image = new Gtk.Image.from_icon_name ("brightness-display-symbolic") {
            pixel_size = 48
        };

        var monitor_label = new Gtk.Label (brightness_manager.get_monitor_name (index)) {
            margin_start = 2,
            margin_top = 2,
            halign = Gtk.Align.START
        };

        if (index == 0) {
            monitor_label.set_text (_("%s (Primary)".printf (monitor_label.get_text ())));
        }

        brightness_slider = new Gtk.Scale.with_range (HORIZONTAL, 0, 1, 0.1) {
            margin_start = 2,
            margin_end = 2,
            hexpand = true,
            draw_value = false,
            width_request = 175
        };

        var slider_box = new Granite.Box (VERTICAL, NONE) {
            hexpand = true,
            vexpand = true,
            homogeneous = true
        };

        slider_box.append (monitor_label);
        slider_box.append (brightness_slider);

        var box = new Granite.Box (HORIZONTAL, HALF) {
            hexpand = true,
            margin_start = 6,
            margin_end = 12
        };

        box.append (image);
        box.append (slider_box);

        child = box;

        slider_signal = brightness_slider.value_changed.connect (on_value_changed_internally);
        bm_signal = brightness_manager.monitor_brightness_changed.connect (on_value_changed_externally);

        brightness_slider.set_value (brightness_manager.get_monitor_brightness (index));
    }

    // We'd need to disable signals temporary here, so there wouldn't be a vicious signal loop
    private void on_value_changed_internally (Gtk.Range value) {
        SignalHandler.block (brightness_manager, bm_signal);
        brightness_manager.set_monitor_brightness (index, value.get_value ());
        SignalHandler.unblock (brightness_manager, bm_signal);
    }

    private void on_value_changed_externally (int ch_index, double value) {
        if (index != ch_index) {
            return;
        }

        SignalHandler.block (brightness_slider, slider_signal);
        brightness_slider.set_value (value);
        SignalHandler.unblock (brightness_slider, slider_signal);
    }

    private bool on_scroll (Gtk.EventControllerScroll controller, double dx, double dy) {
        return Utils.handle_local_scroll_event ((Gdk.ScrollEvent) controller.get_current_event (), index);
    }
}
