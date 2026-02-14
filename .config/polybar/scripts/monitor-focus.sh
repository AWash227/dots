#!/bin/bash
# Shows a colored dot on the focused monitor's bar
print_status() {
    FOCUSED=$(bspc query -M -m focused --names)
    if [ "$FOCUSED" = "$MONITOR" ]; then
        echo "%{F#5e81ac}●%{F-}"
    else
        echo "%{F#555555}●%{F-}"
    fi
}

print_status

bspc subscribe monitor_focus | while read -r _; do
    print_status
done
