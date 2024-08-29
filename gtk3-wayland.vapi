[CCode (cprefix = "Gdk", lower_case_cprefix = "gdk_")]
namespace Gdk {
    [CCode (cheader_filename = "gdk/gdkwayland.h", type_id = "gdk_wayland_window_get_type()")]
    public class WaylandWindow : Gdk.Window {
        [CCode (has_construct_function = false)]
        protected WaylandWindow();
        public unowned Wl.Surface get_wl_surface ();
    }
    [CCode (cheader_filename = "gdk/gdkwayland.h", type_id = "gdk_wayland_display_get_type()")]
    public class WaylandDisplay : Gdk.Display {
        [CCode (has_construct_function = false)]
        protected WaylandDisplay();
        public unowned Wl.Display get_wl_display ();
    }
}