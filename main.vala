using Gtk;
using Gst;
using Json;

public class DemoApp : Window {
        protected Pipeline pipeline;
        protected Element src;
        protected Element capsfilter;
        protected FlowBox propbox;
        protected Gst.Video.Overlay? overlay = null;
        protected Devices devices = null;
        protected ComboBoxText devices_box;
        
        construct {
                EventBox video_area;
                uint *handle = null;

                pipeline = new Pipeline(null);
                src = ElementFactory.make ("libcamerasrc", "src");
                capsfilter = ElementFactory.make ("capsfilter", "capsfilter");
                var sink = ElementFactory.make ("waylandsink", "sink");

                capsfilter["caps"] = new Caps.simple("video/x-raw", 
                    "format", Type.STRING, "YUY2",null);

                pipeline.add_many(src, capsfilter, sink);
                src.link(capsfilter);
                capsfilter.link(sink);
                
                /*
                    Create a event box and use it as a display target for the waylandsink
                 */
                video_area = new EventBox();
                video_area.visible = true;
                video_area.app_paintable = true;

                video_area.realize.connect(() => {
                    Gdk.WaylandWindow window = video_area.get_window() as Gdk.WaylandWindow;
                    handle = (uint*) (window.get_wl_surface());    
                });
 
                video_area.draw.connect(() => {
                    if (overlay != null) {
                        Gtk.Allocation alloc =  Gtk.Allocation();
                        video_area.get_allocation(out alloc);
                        overlay.set_render_rectangle(alloc.x, alloc.y, alloc.width, alloc.height);
                    }
                    return false;    
                });

                sink.bus.set_sync_handler((bus,message) => {
                    if(Gst.Video.is_video_overlay_prepare_window_handle_message (message)) {
                        overlay = message.src as Gst.Video.Overlay;
                        assert (overlay != null);
                        if (handle != null) {
                            Gtk.Allocation alloc = Gtk.Allocation();
                            video_area.get_allocation(out alloc);
                            overlay.set_window_handle (handle);
                            overlay.set_render_rectangle(alloc.x, alloc.y, alloc.width, alloc.height);
                        }  
                        return Gst.BusSyncReply.DROP;
                    } else if (Gst.Wayland.is_wl_display_handle_need_context_message(message)) {
                        Gst.Element element = message.src as Gst.Element;
                        Gdk.WaylandDisplay gdk_display = video_area.get_display() as Gdk.WaylandDisplay;
                        unowned Wl.Display display = gdk_display.get_wl_display();
                        Gst.Context context = Gst.Wayland.display_handle_context_new(display);
                        element.set_context(context);
                        return Gst.BusSyncReply.DROP;
                    }
                    return Gst.BusSyncReply.PASS;
                });    

                var vbox = new Box (Gtk.Orientation.VERTICAL, 0);
                vbox.pack_start (video_area, true, true);

                var play_button = new Button.from_icon_name ("media-playback-start", Gtk.IconSize.BUTTON);
                play_button.clicked.connect (on_play);
                devices_box = new ComboBoxText ();
                devices_box.changed.connect(on_change_device);
                var stop_button = new Button.from_icon_name ("media-playback-stop", Gtk.IconSize.BUTTON);
                stop_button.clicked.connect (on_stop);

                propbox = new FlowBox();
                vbox.pack_start(propbox, false);

                var bb = new ButtonBox (Orientation.HORIZONTAL);
                bb.add (play_button);
                bb.add (devices_box);
                bb.add (stop_button);
                vbox.pack_start (bb, false);

                add (vbox);
                destroy.connect(Gtk.main_quit);
                Idle.add(create_device_list);
        }

        bool create_device_list() {
            devices = new Devices ();
            devices.devices.foreach((f) => {
                devices_box.append_text  (f.display_name);
                return true;
            });
            devices_box.set_active(0);
            return false;
        }
        
        void on_play() {
            pipeline.set_state (Gst.State.PLAYING);
        }
        
        void on_stop() {
            pipeline.set_state (Gst.State.NULL);
        }

        void on_change_device() {
            on_stop();
            var wanted_caps = Caps.from_string("video/x-raw,format=YUY2,width=1920,height=1080;video/x-raw,format=YUY2,width=1280,height=720");
            devices.devices.foreach( (f) => {
                if (f.display_name == devices_box.get_active_text()) {
                    f.reconfigure_element(src);
                    var caps = f.caps.intersect(wanted_caps, CapsIntersectMode.FIRST);
                    if (caps.is_empty()) {
                        caps = new Caps.simple("video/x-raw", "format", Type.STRING, "YUY2", null);
                    }
                    capsfilter["caps"] = caps;
                }
                return true;
            });
            on_play();
        }

        public void load_config(string filename) {
            var parser = new Json.Parser();
            try {
                parser.load_from_file(filename);
            } catch(Error e) {
                printerr("error: %s\n", e.message);
                printerr("Not generating controls.\n");
                return;
            }
            var root = parser.get_root().get_object();
            var props = root.get_array_member("Properties");            
            
            foreach (var propnode in props.get_elements())
            {   
                var prop = propnode.get_object();
                var name = prop.get_string_member("name");
                var type = prop.get_string_member("type");
                var box = new Box(Orientation.HORIZONTAL, 0);
                var label = new Label(name);
                box.pack_start(label, false, false, 0);
                propbox.add(box);
                switch (type) {
                    case "slider":
                    {
                        var min = prop.get_double_member("min");
                        var max = prop.get_double_member("max");
                        var step = prop.get_double_member("step");
                        var value = prop.get_double_member("value");
                        var data_type = prop.get_string_member("data_type");
                        var adj = new Adjustment(value, min, max+1, step, 1.0, 1.0);
                        var slider = new Scale(Orientation.HORIZONTAL, adj);
                        
                        slider.value_changed.connect(() => {
                            switch(data_type){
                                case "double":
                                    src[name] = slider.get_value();
                                    break;
                                default:
                                    src[name] = (int)slider.get_value();
                                    break;
                            }
                        });
                        slider.set_size_request(180, -1);
                        box.pack_start(slider, true, true, 0);
                    }
                    break;
                    case "toggle":
                    {
                        var value = prop.get_boolean_member("value");
                        var tbox = new Box(Orientation.VERTICAL, 0);
                        box.pack_start(tbox, true, false, 0);
                        var toggle = new Switch();
                        toggle.set_active(value);
                        toggle.notify["active"].connect(() => {
                            src[name] = toggle.get_active();
                        });
                        tbox.pack_start(toggle, true, false, 0);
                    }
                    break;
                    default:
                        stderr.printf(@"Unknown type from json file: $(type)\n");
                        break;
                }
            }
        }

        public static int main (string[] args) {
                Gst.init (ref args);
                Gtk.init (ref args);

                string? config_filename = "/usr/share/gst-mipi-demo/config.json";

                GLib.OptionEntry[] options = {
                    { "config", 'f', OptionFlags.NONE, OptionArg.FILENAME, ref config_filename, "Filename of configuration JSON", "CONFIGFILE"}
                };

                var opt_context = new OptionContext("- A simple MIPI demo application");
                opt_context.set_help_enabled(true);
                opt_context.add_main_entries(options, null);
                try {
                    opt_context.parse(ref args);
                } catch(OptionError e) {
                    printerr("error: %s\n", e.message);
                    return 1;
                }

                var app = new DemoApp ();
                app.maximize();
                app.load_config(config_filename);
                app.show_all ();

                Gtk.main ();

                return 0;
        }
}
