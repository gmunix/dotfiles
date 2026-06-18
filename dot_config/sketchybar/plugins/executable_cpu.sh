#!/bin/sh

cores="$(sysctl -n hw.ncpu 2>/dev/null)"
if ! [ "$cores" -gt 0 ] 2>/dev/null; then
  cores=1
fi

usage="$(ps -A -o %cpu= | awk -v cores="$cores" '
  { sum += $1 }
  END {
    usage = sum / cores
    if (usage > 100) usage = 100
    printf "%.0f", usage
  }
')"

if [ -z "$usage" ]; then
  exit 0
fi

sketchybar --set "$NAME" label="${usage}%"
