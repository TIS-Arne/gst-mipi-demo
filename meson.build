project('MIPI demo app', 'vala', 'c')

libgstwayland = meson.get_compiler('c').find_library('gstwayland-1.0')

dependencies = [
    dependency('glib-2.0'),
    dependency('gdk-3.0'),
    dependency('gtk+-3.0'),
    dependency('gobject-2.0'),
    dependency('gee-0.8'),
    dependency('gstreamer-1.0'),
    dependency('gstreamer-video-1.0'),
    dependency('json-glib-1.0'),
    dependency('wayland-client'),
    libgstwayland
]


sources = files('main.vala', 'devices.vala', 'gtk3-wayland.vapi', 'gstreamer-wayland-1.0.vapi')

executable('gst-mipi-demo', sources, dependencies: dependencies, install: true)
install_data('config.json', install_dir: get_option('datadir') / 'gst-mipi-demo')

