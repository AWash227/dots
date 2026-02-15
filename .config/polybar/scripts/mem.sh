#!/bin/bash
. ~/.config/bspwm/theme.env
U="%{T4}%{F${HOST_COLOR_DIM}} G%{T-}%{F-}"
free -m | awk -v u="$U" '/Mem:/{printf "MEM %.1f/%.1f%s\n", $3/1024, $2/1024, u}'
