#!/bin/sh
[[ -f ~/.xprofile ]] && source ~/.xprofile

pgrep -x fcitx5 >/dev/null || fcitx5 &

# Kill any existing instances
killall -q polybar dunst picom stt

# Monitor layout: DP-2 on the left, HDMI-0 on the right
xrandr --output DP-2 --mode 1920x1080 --rate 180 --pos 0x0 --output HDMI-0 --mode 1920x1080 --pos 1920x0 --primary

# Give X time to settle
sleep 1

# Start compositor
picom --config ~/.config/picom/picom.conf &

redshift &

# Launch notification daemon
dunst &

# Launch your speech-to-text daemon
# stt &

# Give stt time to open and apply a bspwm rule to float + stay above
sleep 0.5
bspc rule -a stt:X window_above=on state=floating layer=above

# Start window manager (bspwm takes over control)
exec bspwm

