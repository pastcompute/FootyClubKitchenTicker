#!/bin/bash

xterm -fn fixed -uc -cr black -bg black -geom 120x1+0+0 -bw 0 -title TICKER \
      -e ticker --foreground=yellow --background=black --delay=0.2 -l Test123 &
X=$!

wmctrl -r TICKER -b add,above
wmctrl -r TICKER -b remove,maximized_vert

wait $X

