#!/bin/bash
xclock -d -chime -geom 120x36+0+48 -strftime '%d %b %H:%M' &
PID=$!
wmctrl -r xclock -b add,above
wait $PID
