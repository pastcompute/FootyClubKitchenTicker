#!/bin/bash

# apt-get install ticker
# Need to work out the widths for 1920, etc @ given larger font size

xterm -uc -cr black -bg black -font lucidasanstypewriter-bold-24 -geom 33x1 -e ticker --foreground=yellow --background=black -l Test123
