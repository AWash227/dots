#!/bin/sh
[[ -f ~/.xprofile ]] && source ~/.xprofile

# Start window manager (bspwm takes over control)
exec bspwm

