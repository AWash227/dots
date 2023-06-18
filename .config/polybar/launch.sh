#!/bin/sh

# Terminate already running bar instances
polybar-msg cmd quit

# Nuclear Option:
# killall -q polybar
#
# Wait until the processes have been shut down
#while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch bar1 and bar2
#MONITORS=$(xrandr --query | grep " connected" | cut -d" " -f1)
echo "---" | tee -a /tmp/polybar-bottom.log 
#polybar  2>&1 | tee -a /tmp/polybar1.log & disown
polybar bottom 2>&1 | tee -a /tmp/polybar-bottom.log & disown

#MONITORS=$MONITORS polybar top &
#MONITOR=$MONITORS polybar bottom;

echo "Bars launched..."
