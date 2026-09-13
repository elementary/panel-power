/*
 * Copyright 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Authored by: Denis Garaev <garaevdi@outlook.com>
 */

public class Power.Services.BrightnessManager : Object {
    private const string GALA_INTERFACE = "io.elementary.gala";
    private const string GALA_PATH = "/io/elementary/gala/BrightnessManager";

    public signal void connected ();
    public signal void monitors_changed ();
    public signal void monitor_brightness_changed (int index, double value);

    private Power.Services.DBusInterfaces.GalaBrightnessManager? gala_brightness_manager;

    private static BrightnessManager? instance = null;

    public bool present {
        get {
            if (gala_brightness_manager == null) {
                return false;
            }

            try {
                if (gala_brightness_manager.get_n_monitors () == 0) {
                    return false;
                }
            } catch {}

            return true;
        }
    }

    construct {
        init.begin ((obj, res) => {
            try {
                init.end (res);
                connect_signals ();
            } catch {}
        });
    }

    public static Power.Services.BrightnessManager get_default () {
        if (instance == null) {
            instance = new BrightnessManager ();
        }

        return instance;
    }

    public int get_n_monitors () {
        try {
            return gala_brightness_manager.get_n_monitors ();
        } catch (Error e) {
            warning ("Couldn't get number of monitors: %s", e.message);
            return -1;
        }
    }

    public double get_global_brightness () {
        try {
            return gala_brightness_manager.get_global_brightness ().clamp (0.0001, 1.0);
        } catch (Error e) {
            warning ("Couldn't get global brightness: %s", e.message);
            return -1.0f;
        }
    }

    public void set_global_brightness (double value) {
        try {
            gala_brightness_manager.set_global_brightness (value.clamp (0.0001, 1.0));
        } catch (Error e) {
            warning ("Coulnd't set global brightness: %s", e.message);
        }
    }

    public string get_monitor_name (int index) {
        try {
            return gala_brightness_manager.get_monitor_name (index);
        } catch (Error e) {
            warning ("Couldn't get %n monitor's name: %s", index, e.message);
            return "";
        }
    }

    public double get_monitor_brightness (int index) {
        try {
            return gala_brightness_manager.get_monitor_brightness (index).clamp (0.0001, 1);
        } catch (Error e) {
            warning ("Couldn't get %n monitor's brightness: %s", index, e.message);
            return -1.0f;
        }
    }

    public void set_monitor_brightness (int index, double value) {
        try {
            gala_brightness_manager.set_monitor_brightness (index, value.clamp (0.0001, 1));
        } catch (Error e) {
            warning ("Coulnd't set %n monitor's brightness: %s", index, e.message);
        }
    }


    private async void init () throws Error {
        try {
            gala_brightness_manager = yield Bus.get_proxy (BusType.SESSION, GALA_INTERFACE, GALA_PATH);
            connected ();
        } catch (Error e) {
            warning ("Couldn't connect to Gala's BrightnessManager: %s", e.message);
            throw e;
        }
    }

    private void connect_signals () {
        gala_brightness_manager.monitors_changed.connect (on_monitors_changed);
        gala_brightness_manager.monitor_brightness_changed.connect (on_monitor_brightness_changed);
    }

    private void on_monitors_changed () {
        monitors_changed ();
    }

    private void on_monitor_brightness_changed (int index, double value) {
        monitor_brightness_changed (index, value);
    }
}
