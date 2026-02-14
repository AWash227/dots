#!/bin/bash
# Cycle to prev/next paired workspace
DIR=$1
CURRENT=$(bspc query -D -d focused --names)
# Strip any trailing letter suffix to get the number
NUM=${CURRENT%[a-z]}

if [ "$DIR" = "next" ]; then
    NEXT=$((NUM % 10 + 1))
else
    NEXT=$(( (NUM - 2 + 10) % 10 + 1 ))
fi

~/.config/bspwm/switch-workspace.sh "$NEXT"
