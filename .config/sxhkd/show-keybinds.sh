#!/bin/bash
# Parse sxhkdrc and display keybindings in rofi on the focused monitor
awk '
/^#{3,}/ { next }
/^#/ {
    sub(/^#+ */, "")
    desc = desc ? desc " | " $0 : $0
    next
}
/^[^ \t#]/ {
    if (desc != "") {
        printf "%-35s  →  %s\n", $0, desc
    }
    desc = ""
    next
}
{ desc = "" }
' ~/.config/sxhkd/sxhkdrc | rofi -dmenu -i -p "Keybindings" -no-custom -m "$(bspc query -M -m focused --names)"
