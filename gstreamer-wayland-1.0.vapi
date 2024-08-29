[CCode (cprefix = "Gst", lower_case_cprefix = "gst_")]
namespace Gst {
    namespace Wayland {
        [CCode (cheader_filename = "gst/wayland/wayland.h", cname = "gst_is_wl_display_handle_need_context_message")]
		public static bool is_wl_display_handle_need_context_message (Gst.Message msg);
        [CCode (cheader_filename = "gst/wayland/wayland.h", cname = "gst_wl_display_handle_context_new")]
        public static unowned Gst.Context display_handle_context_new(Wl.Display display);
    }
}