project('MIPI demo app', 'vala', 'c')

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gstreamer-1.0'),
    dependency('gtk+-3.0'),
    dependency('json-glib-1.0')
]

sources = files('main.vala')

executable('gst-mipi-demo', sources, dependencies: dependencies, install: true)
install_data('props.json', install_dir: get_option('datadir') / 'gst-mipi-demo')

