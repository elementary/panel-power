public class Power.Utils {

    private const double BRIGHTNESS_STEP = 0.005;
    private static double total_y_delta = 0;
    private static double total_x_delta = 0;

    public static bool handle_global_scroll_event (Gdk.ScrollEvent e) {
        var bm = Power.Services.BrightnessManager.get_default ();
        if (e.get_device () == null || bm.has_monitors == false) {
            return false;
        }

        var dir = calculate_delta (e);

        if (dir.abs () > 0.0) {
            total_y_delta = 0.0;
            total_x_delta = 0.0;
            var delta = (bm.get_global_brightness () + dir * BRIGHTNESS_STEP);
            bm.set_global_brightness (delta);
        }

        return Gdk.EVENT_STOP;
    }

    public static bool handle_local_scroll_event (Gdk.ScrollEvent e, int index) {
        var bm = Power.Services.BrightnessManager.get_default ();
        if (e.get_device () == null || bm.has_monitors == false) {
            return false;
        }

        var dir = calculate_delta (e);

        if (dir.abs () > 0.0) {
            total_y_delta = 0.0;
            total_x_delta = 0.0;
            var delta = (bm.get_monitor_brightness (index) + dir * BRIGHTNESS_STEP);
            bm.set_monitor_brightness (index, delta);
        }

        return Gdk.EVENT_STOP;
    }

    /* Smooth scrolling vertical support. Accumulate delta_y until threshold exceeded before actioning */
    private static double calculate_delta (Gdk.ScrollEvent e) {
        var dir = 0.0;
        bool natural_scroll;
        var event_device = e.get_device ();
        var mouse_settings = new GLib.Settings ("org.gnome.desktop.peripherals.mouse");
        var touchpad_settings = new GLib.Settings ("org.gnome.desktop.peripherals.touchpad");

        if (event_device.source == Gdk.InputSource.MOUSE) {
            natural_scroll = mouse_settings.get_boolean ("natural-scroll");
        } else if (event_device.source == Gdk.InputSource.TOUCHPAD) {
            natural_scroll = touchpad_settings.get_boolean ("natural-scroll");
        } else {
            natural_scroll = true;
        }

        double delta_x, delta_y;
        e.get_deltas (out delta_x, out delta_y);

        switch (e.get_direction ()) {
        case Gdk.ScrollDirection.SMOOTH:
            var abs_x = double.max (delta_x.abs (), 0.0001);
            var abs_y = double.max (delta_y.abs (), 0.0001);

            if (abs_y / abs_x > 2.0) {
                total_y_delta += delta_y;
            } else if (abs_x / abs_y > 2.0) {
                total_x_delta += delta_x;
            }

            break;
        case Gdk.ScrollDirection.UP:
            total_y_delta = -1.0;
            break;
        case Gdk.ScrollDirection.DOWN:
            total_y_delta = 1.0;
            break;
        case Gdk.ScrollDirection.LEFT:
            total_x_delta = -1.0;
            break;
        case Gdk.ScrollDirection.RIGHT:
            total_x_delta = 1.0;
            break;
        default:
            break;
        }

        if (total_y_delta.abs () * BRIGHTNESS_STEP > 0.001) {
            dir = natural_scroll ? total_y_delta : -total_y_delta;
        } else if (total_x_delta.abs () * BRIGHTNESS_STEP > 0.001) {
            dir = natural_scroll ? -total_x_delta : total_x_delta;
        }

        return dir;
    }
}
