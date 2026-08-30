/*
 * Copyright (c) 2011-2021 elementary LLC. (https://elementary.io)
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

public class Power.Services.DeviceManager : Object {
    private const string UPOWER_INTERFACE = "org.freedesktop.UPower";
    private const string UPOWER_PATH = "/org/freedesktop/UPower";

    private const string GALA_INTERFACE = "io.elementary.gala";
    private const string GALA_PATH = "/io/elementary/gala/BrightnessManager";

    private static DeviceManager? instance = null;

    private DBusInterfaces.UPower? upower = null;
    private DBusInterfaces.BrightnessManager? brightness_manager = null;

    public Services.Backlight backlight { get; construct; }
    public Gee.HashMap<string, Device> devices { get; private set; }
    public Gee.Iterator batteries { get; private set; }
    public Device display_device { get; private set; }
    public bool has_battery { get; private set; }
    public bool on_battery { get; private set; }
    public bool on_low_battery { get; private set; }

    public signal void battery_registered (string device_path, Device battery);
    public signal void battery_deregistered (string device_path);

    public signal void monitors_changed ();
    public signal void monitor_brightness_changed (int index, double value);

    construct {
        backlight = new Services.Backlight ();

        connect_to_bus.begin ((obj, res) => {
            if (connect_to_bus.end (res)) {
                update_properties ();
                read_devices ();
                update_batteries ();
                connect_signals ();
            }
        });
    }

    // singleton one class object in memory. use instance to get data.
    public static unowned DeviceManager get_default () {
        if (instance == null) {
            instance = new DeviceManager ();
        }

        return instance;
    }

    private async bool connect_to_bus () {
        devices = new Gee.HashMap<string, Device> ();

        try {
            upower = yield Bus.get_proxy (
                BusType.SYSTEM,
                UPOWER_INTERFACE,
                UPOWER_PATH,
                DBusProxyFlags.NONE
            );
            debug ("Connection to UPower bus established");

            brightness_manager = yield Bus.get_proxy (
                BusType.SESSION,
                GALA_INTERFACE,
                GALA_PATH,
                DBusProxyFlags.GET_INVALIDATED_PROPERTIES
            );
            debug ("Connection to Power Settings bus established");

            return true;
        } catch (Error e) {
            critical ("Connecting to UPower or PowerSettings bus failed: %s", e.message);

            return false;
        }
    }

    private bool determine_attached_device (ObjectPath device_path) {
        var device = new Device (device_path);

        // this prevents from showing weird devices to show up.
        // such as a laptops track pad pointer to show up as wacom tablet with no battery.
        if ((device.technology == Device.Technology.UNKNOWN) &&
            (device.state == Device.State.UNKNOWN)) {
            return false;
        }
        return true;
    }

    public void read_devices () {
        if (upower == null) {
            return;
        }

        try {
            // Add Display Device for Panel display
            var display_device_path = upower.get_display_device ();
            display_device = new Device (display_device_path);
            // Fetch other devices for Detail in Panel
            var devices = upower.enumerate_devices ();
            foreach (ObjectPath device_path in devices) {
                if (determine_attached_device (device_path) == true) {
                    register_device (device_path);
                }
            }
        } catch (Error e) {
            critical ("Reading UPower devices failed: %s", e.message);
        }
    }

    private void connect_signals () requires (upower != null && brightness_manager != null) {
        upower.g_properties_changed.connect (() => {
            update_properties ();
            update_batteries ();
        });

        upower.DeviceAdded.connect (register_device);
        upower.DeviceRemoved.connect (deregister_device);

        brightness_manager.monitors_changed.connect (monitors_changed_cb);
        brightness_manager.monitor_brightness_changed.connect (monitor_brightness_changed_cb);
    }

    private void update_properties () requires (upower != null) {
        on_battery = upower.on_battery;
    }

    private void update_batteries () {
        batteries = devices.filter ((entry) => {
            var device = entry.value;
            return device.is_a_battery;
        });

        has_battery = batteries.has_next ();
    }

    private void register_device (ObjectPath device_path) {
        var device = new Device (device_path);

        devices.@set (device_path, device);
        debug ("Device \"%s\" registered", device_path);
        update_batteries ();

        if (device.is_a_battery) {
            battery_registered (device_path, device);
        }
    }

    private void deregister_device (ObjectPath device_path) {
        if (!devices.has_key (device_path)) {
            return;
        }

        var device = devices.@get (device_path);

        if (!devices.unset (device_path)) {
            return;
        }

        debug ("Device \"%s\" deregistered", device_path);
        update_batteries ();

        if (device.is_a_battery) {
            battery_deregistered (device_path);
        }
    }

    private void monitors_changed_cb () {
        monitors_changed ();
    }

    private void monitor_brightness_changed_cb (int index, double value) {
        monitor_brightness_changed (index, value);
    }

    public double get_monitor_brightness (int index) {
        if (brightness_manager != null) {
            try {
                return brightness_manager.get_monitor_brightness (index);
            } catch (Error e) {
                warning ("Couldn't get monitor's brightness: %s", e.message);
            }
        }
        return -1;
    }

    public void set_monitor_brightness (int index, double value) {
        if (brightness_manager != null) {
            try {
                brightness_manager.set_monitor_brightness (index, value);
            } catch (Error e) {
                warning ("Couldn't set monitor's brightness: %s", e.message);
            }
        }
    }

    public string get_monitor_data (int index) {
        if (brightness_manager != null) {
            try {
                return brightness_manager.get_monitor_name (index);
            } catch (Error e) {
                warning ("Couldn't get monitor's data: %s", e.message);
            }
        }
        return "";
    }

    public int get_monitor_count () {
        if (brightness_manager != null) {
            try {
                return brightness_manager.get_n_monitors ();
            } catch (Error e) {
                warning ("Couldn't get monitor's count: %s", e.message);
            }
        }
        return 0;
    }

    public void change_global_brightness (double change) {
        try {
            brightness_manager.set_global_brightness ((brightness_manager.get_global_brightness () + change).clamp (0.0, 1.0));
        } catch (Error e) {
            warning ("Couldn't set global brightness: %s", e.message);
        }
    }
}
