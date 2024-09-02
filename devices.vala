using Gee;
using Gst;

public class Devices : GLib.Object {
    public TreeSet<Device> devices {public get; private set;}

    private DeviceMonitor monitor;

    construct {
        devices = new TreeSet<Device> ();
        monitor = new DeviceMonitor ();
        monitor.add_filter("Video/Source", new Caps.simple("video/x-raw", 
            "format", Type.STRING, "YUY2", null));
        monitor.start();

        var devs = monitor.get_devices ();
        unowned GLib.List<Device> item = devs;
        while (item != null) {
            devices.add(item.data);
            item = item.next;
        }
    }

    public void print_devices() {
        foreach (var device in devices) {
            print(@"Display Name: $(device.display_name)\n");
            print(@"Device Class: $(device.device_class)\n");
            var caps_string = device.caps.to_string();
            print(@"Caps: $(caps_string)\n");
            if (device.properties != null ) {
                for (int i = 0; i < device.properties.n_fields(); i++) {
                    var name = device.properties.nth_field_name(i);
                    print(@"Property: $(name)\n");
                }
            }
        }
    }
}