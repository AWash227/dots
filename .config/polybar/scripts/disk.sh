#!/bin/bash
. ~/.config/bspwm/theme.env
U="%{T4}%{F${HOST_COLOR_DIM}} G%{T-}%{F-}"
read -r used total <<< "$(df -BG / | awk 'NR==2{gsub(/G/,""); print $3, $2}')"
echo "DISK ${used}/${total}${U}"
