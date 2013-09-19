#!/bin/bash

MESSAGE="$(cat $HOME/sponsors.txt | perl -pi -e 's/\n/   /' )"

# ticker -l - bottom of terminal...
# If geom width too large, we see nothing ... ?
xterm -fa "FreeMono" -fs 32  -uc -cr black -bg black -geom 48x1+0+0 -bw 0 -title TICKERTICKER \
      -e ticker --foreground=yellow --background=black --delay=0.1 -l "$MESSAGE" &
X=$!

wmctrl -r TICKERTICKER -b add,above
wmctrl -r TICKERTICKER -b remove,maximized_vert,maximized_horz

wait $X

