#!/bin/bash
. ~/.config/bspwm/theme.env
U="%{T4}%{F${HOST_COLOR_DIM}} %%{F-}%{T-}"
MUTED=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -o 'yes')
VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+%' | head -1 | tr -d '%')

if [ "$MUTED" = "yes" ]; then
    echo "VOL muted"
else
    echo "VOL ${VOL}${U}"
fi
