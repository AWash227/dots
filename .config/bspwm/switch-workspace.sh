#!/bin/bash
# Switch all monitors to workspace N simultaneously
N=$1
SUFFIXES="abcdefghijklmnopqrstuvwxyz"
FOCUSED=$(bspc query -M -m focused)
MONITORS=($(bspc query -M --names))

if [ ${#MONITORS[@]} -gt 1 ]; then
    for i in "${!MONITORS[@]}"; do
        bspc desktop "${N}${SUFFIXES:$i:1}" -f
    done
    bspc monitor "$FOCUSED" -f
else
    bspc desktop "$N" -f
fi
