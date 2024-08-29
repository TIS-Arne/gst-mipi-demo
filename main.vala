using Gtk;
using Gst;
using Json;

public class DemoApp : Window {
        Pipeline pipeline;
        Element src;
        FlowBox propbox;
        
        construct {
                Widget video_area;

                pipeline = new Pipeline(null);
                src = ElementFactory.make ("libcamerasrc", "src");
                var convert = ElementFactory.make ("videoconvert", "convert");
                var gtksink = ElementFactory.make ("gtksink", "sink");
                gtksink.get ("widget", out video_area);

                pipeline.add_many(src, convert, gtksink);
                
                src.link(convert);
                convert.link(gtksink);
                
                var vbox = new Box (Gtk.Orientation.VERTICAL, 0);
                vbox.pack_start (video_area);

                var play_button = new Button.from_icon_name ("media-playback-start", Gtk.IconSize.BUTTON);
                play_button.clicked.connect (on_play);
                var stop_button = new Button.from_icon_name ("media-playback-stop", Gtk.IconSize.BUTTON);
                stop_button.clicked.connect (on_stop);

                propbox = new FlowBox();
                vbox.pack_start(propbox);

                var bb = new ButtonBox (Orientation.HORIZONTAL);
                bb.add (play_button);
                bb.add (stop_button);
                vbox.pack_start (bb, false);

                add (vbox);
                destroy.connect(Gtk.main_quit);
                on_play();
        }
        
        void on_play() {
                pipeline.set_state (Gst.State.PLAYING);
        }
        
        void on_stop() {
                pipeline.set_state (Gst.State.READY);
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
                        var adj = new Adjustment(value, min, max+1, step, 1.0, 1.0);
                        var slider = new Scale(Orientation.HORIZONTAL, adj);
                        slider.value_changed.connect(() => {
                            src[name] = slider.get_value();
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

                string? config_filename = "/usr/share/gst-mipi-demo/props.json";

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
