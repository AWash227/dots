#!/usr/bin/env bash
set -euo pipefail

# deps: bspwm, rofi, xtitle, xorg-xprop
# usage: show-windows.sh [DESKTOP_NAME]
desk="${1:-}"
if [[ -z "${desk}" ]]; then
  desk="$(bspc query -D -d focused --names)"
fi

# List window node IDs on the desktop
mapfile -t ids < <(bspc query -N -d "$desk" -n .window)

if (( ${#ids[@]} == 0 )); then
  command -v notify-send >/dev/null 2>&1 && notify-send "Workspace ${desk}" "No windows"
  exit 0
fi

# Build menu: "ID<TAB>Class — Title"
lines=()
for id in "${ids[@]}"; do
  # WM_CLASS can be "instance", "ClassName". Take the last quoted string = class.
  klass=$(xprop -id "$id" WM_CLASS 2>/dev/null | awk -F'"' 'NF>=2{print $NF==""?$((NF-1)):$((NF-1))}')
  title=$(xtitle -s "$id" 2>/dev/null || echo "")
  [[ -z "$klass" ]] && klass="?"
  [[ -z "$title" ]] && title="(no title)"
  # Truncate long titles for saner menus (rofi handles long lines but this is nicer)
  short="${title:0:120}"
  lines+=( "${id}\t${klass} — ${short}" )
done

choice="$(printf '%s\n' "${lines[@]}" | rofi -dmenu -i -p "WS ${desk}" )" || exit 1
sel_id="${choice%%$'\t'*}"

# Focus the node; bspwm will jump to its desktop
if [[ -n "$sel_id" ]]; then
  bspc node "$sel_id" -f
fi
