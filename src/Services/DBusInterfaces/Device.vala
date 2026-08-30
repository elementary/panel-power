/*
 * Copyright (c) 2011-2018 elementary LLC. (https://elementary.io)
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

const string HISTORY_TYPE_RATE = "rate";
const string HISTORY_TYPE_CHARGE = "charge";

const string STATISTICS_TYPE_CHARGING = "charging";
const string STATISTICS_TYPE_DISCHARGING = "discharging";

namespace Power.Services.DBusInterfaces {
    public struct HistoryDataPoint {
        uint32 time;
        double value;
        uint32 state;
    }

    public struct StatisticsDataPoint {
        double value;
        double accuracy;
    }

    [DBus (name = "org.freedesktop.UPower.Device")]
    public interface Device : DBusProxy {
        public abstract HistoryDataPoint[] get_history (string type, uint32 timespan, uint32 resolution) throws GLib.Error;

        public abstract StatisticsDataPoint[] get_statistics (string type) throws GLib.Error;
        public abstract void refresh () throws GLib.Error;

        public abstract bool has_history { public get; public set; }
        public abstract bool has_statistics { public get; public set; }
        public abstract bool is_present { public get; public set; }
        public abstract bool is_rechargeable { public get; public set; }
        public abstract bool online { public get; public set; }
        public abstract bool power_supply { public get; public set; }
        public abstract double capacity { public get; public set; }
        public abstract double energy { public get; public set; }
        public abstract double energy_empty { public get; public set; }
        public abstract double energy_full { public get; public set; }
        public abstract double energy_full_design { public get; public set; }
        public abstract double energy_rate { public get; public set; }
        public abstract double luminosity { public get; public set; }
        public abstract double percentage { public get; public set; }
        public abstract double temperature { public  get; public set; }
        public abstract double voltage { public get; public set; }
        public abstract int64 time_to_empty { public get; public set; }
        public abstract int64 time_to_full { public get; public set; }
        public abstract string model { public owned get; public set; }
        public abstract string native_path { public owned get; public set; }
        public abstract string serial { public owned get; public set; }
        public abstract string vendor { public owned get; public set; }
        public abstract uint32 battery_level { get; }
        public abstract uint32 state { public get; public set; }
        public abstract uint32 technology { public get; public set; }
        public abstract uint32 Type { public get; public set; }
        public abstract uint64 update_time { public get; public set; }
    }
}
