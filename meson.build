project('MIPI demo app', 'vala', 'c')

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gstreamer-1.0'),
    dependency('gtk+-3.0'),
    dependency('json-glib-1.0')
]

sources = files('main.vala')

executable('demo-app', sources, dependencies: dependencies)
