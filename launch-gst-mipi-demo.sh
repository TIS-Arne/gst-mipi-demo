#!/bin/sh
if test -z "$XDG_RUNTIME_DIR"; then
    export XDG_RUNTIME_DIR=/var/run/user/`id -u`
    if ! test -d "$XDG_RUNTIME_DIR"; then
        mkdir --parents $XDG_RUNTIME_DIR
        chmod 0700 $XDG_RUNTIME_DIR
    fi
fi
# wait for weston
while [ ! -e  $XDG_RUNTIME_DIR/wayland-1 ] ; do sleep 0.1; done
sleep 1
unset DISPLAY
export WAYLAND_DISPLAY=/var/run/wayland-0
cd /opt/gst-mipi-demo ; XDG_RUNTIME_DIR=/var/run/user/0 ./gst-mipi-demo -f /opt/gst-mipi-demo/config.json
