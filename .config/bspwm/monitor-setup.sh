#!/bin/bash
# Setup monitors left-to-right in the order listed in monitors.conf.
# If monitors.conf doesn't exist, auto-detect all connected monitors.
#
# monitors.conf format (one output per line, left to right):
#   DP-2
#   HDMI-0
#
# Optional mode/rate override:
#   DP-2  1920x1080@180
#   HDMI-0  1920x1080@60
#
# Monitors not in the config are ignored (useful for disabling an output).

CONF=~/.config/bspwm/monitors.conf

auto_detect() {
    # Get native (preferred) mode and highest refresh rate for an output
    xrandr --query | awk -v out="$1" '
        $1==out && / connected/ { found=1; next }
        found && /^[^ ]/ { exit }
        found && /\+/ {
            mode = $1
            best = 0
            for (i=2; i<=NF; i++) {
                gsub(/[*+]/, "", $i)
                r = $i + 0
                if (r > best) best = r
            }
            printf "%s %.2f", mode, best
            exit
        }
    '
}

# Build ordered list of outputs
if [ -f "$CONF" ]; then
    outputs=$(grep -v '^\s*#' "$CONF" | grep -v '^\s*$' | awk '{print $1}')
else
    outputs=$(xrandr --query | awk '/ connected/{print $1}')
fi

xpos=0
for output in $outputs; do
    # Check if actually connected
    xrandr --query | grep -q "^$output connected" || continue

    # Check for override in config
    override=$([ -f "$CONF" ] && grep -m1 "^$output" "$CONF" | awk '{print $2}')

    if [ -n "$override" ]; then
        mode=${override%@*}
        rate=${override#*@}
    else
        read -r mode rate <<< "$(auto_detect "$output")"
    fi

    xrandr --output "$output" --mode "$mode" --rate "$rate" --pos "${xpos}x0"
    width=${mode%%x*}
    xpos=$((xpos + width))
done
