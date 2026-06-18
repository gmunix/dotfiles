#!/bin/sh

page_size="$(pagesize 2>/dev/null)"
total_bytes="$(sysctl -n hw.memsize 2>/dev/null)"

if ! [ "$page_size" -gt 0 ] 2>/dev/null || ! [ "$total_bytes" -gt 0 ] 2>/dev/null; then
  exit 0
fi

usage="$(vm_stat | awk -v page_size="$page_size" -v total_bytes="$total_bytes" '
  /Pages active/ { active = $3 }
  /Pages wired down/ { wired = $4 }
  /Pages occupied by compressor/ { compressed = $5 }
  END {
    gsub(/\./, "", active)
    gsub(/\./, "", wired)
    gsub(/\./, "", compressed)

    usage = ((active + wired + compressed) * page_size / total_bytes) * 100
    if (usage > 100) usage = 100
    printf "%.0f", usage
  }
')"

if [ -z "$usage" ]; then
  exit 0
fi

sketchybar --set "$NAME" label="${usage}%"
