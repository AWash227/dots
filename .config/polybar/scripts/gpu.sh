#!/bin/bash
. ~/.config/bspwm/theme.env
U="%{T4}%{F${HOST_COLOR_DIM}} G%{T-}%{F-}"
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits \
  | awk -F', ' -v u="$U" '{printf "VRAM %.1f/%.1f%s\n", $1/1024, $2/1024, u}'
