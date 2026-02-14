#!/bin/bash
# Move focused window to workspace N on the same monitor
N=$1
SUFFIXES="abcdefghijklmnopqrstuvwxyz"
MONITORS=($(bspc query -M --names))
CURRENT_MONITOR=$(bspc query -M -m focused --names)

if [ ${#MONITORS[@]} -gt 1 ]; then
    for i in "${!MONITORS[@]}"; do
        if [ "${MONITORS[$i]}" = "$CURRENT_MONITOR" ]; then
            bspc node -d "${N}${SUFFIXES:$i:1}"
            break
        fi
    done
else
    bspc node -d "$N"
fi
