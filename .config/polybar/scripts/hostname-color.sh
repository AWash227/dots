#!/bin/bash
# Display hostname with a deterministic background color and contrasting text
HOST=$(hostname)
HASH=$(echo -n "$HOST" | md5sum | head -c 6)
R=$((16#${HASH:0:2}))
G=$((16#${HASH:2:2}))
B=$((16#${HASH:4:2}))

# Perceived luminance — pick black or white text for contrast
LUM=$(( (299 * R + 587 * G + 114 * B) / 1000 ))
if [ $LUM -gt 128 ]; then
    FG="#000000"
else
    FG="#ffffff"
fi

echo "%{B#${HASH}}%{F${FG}}%{T2} ${HOST} %{T-}%{B- F-}"
