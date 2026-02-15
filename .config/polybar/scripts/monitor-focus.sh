#!/bin/bash
# Shows a colored dot on the focused monitor's bar
. ~/.config/bspwm/theme.env

print_status() {
    FOCUSED=$(bspc query -M -m focused --names)
    if [ "$FOCUSED" = "$MONITOR" ]; then
        echo "%{F${HOST_COLOR}}●%{F-}"
    else
        echo "%{F#555555}●%{F-}"
    fi
}

print_status

bspc subscribe monitor_focus | while read -r _; do
    print_status
done
