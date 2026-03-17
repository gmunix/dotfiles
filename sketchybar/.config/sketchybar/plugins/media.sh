#!/bin/sh

set_placeholder() {
  sketchybar --set "$NAME" drawing=on icon="󰎈" label="No media"
}

spotify_running() {
  osascript -e 'application "Spotify" is running' 2>/dev/null
}

music_running() {
  osascript -e 'application "Music" is running' 2>/dev/null
}

get_spotify_field() {
  field="$1"
  osascript -e "tell application \"Spotify\" to get ${field}" 2>/dev/null
}

get_music_field() {
  field="$1"
  osascript -e "tell application \"Music\" to get ${field}" 2>/dev/null
}

toggle_playback() {
  if [ "$(spotify_running)" = "true" ]; then
    osascript -e 'tell application "Spotify" to playpause' >/dev/null 2>&1
    return
  fi

  if [ "$(music_running)" = "true" ]; then
    osascript -e 'tell application "Music" to playpause' >/dev/null 2>&1
  fi
  sleep 0.2
}

if [ "$SENDER" = "mouse.clicked" ]; then
  toggle_playback
fi

title=""
artist=""
playback_rate=""

if [ "$(spotify_running)" = "true" ]; then
  title="$(get_spotify_field 'name of current track')"
  artist="$(get_spotify_field 'artist of current track')"
  state="$(get_spotify_field 'player state')"
  if [ "$state" = "playing" ]; then
    playback_rate="1"
  else
    playback_rate="0"
  fi
elif [ "$(music_running)" = "true" ]; then
  title="$(get_music_field 'name of current track')"
  artist="$(get_music_field 'artist of current track')"
  state="$(get_music_field 'player state as text')"
  if [ "$state" = "playing" ]; then
    playback_rate="1"
  else
    playback_rate="0"
  fi
fi

if [ -z "$title" ] || [ "$title" = "null" ] || [ "$title" = "(null)" ]; then
  set_placeholder
  exit 0
fi

if [ -n "$artist" ] && [ "$artist" != "null" ] && [ "$artist" != "(null)" ]; then
  label="$title - $artist"
else
  label="$title"
fi

icon="󰎈"
if [ "$playback_rate" = "0" ] || [ "$playback_rate" = "0.0" ]; then
  icon="󰏤"
fi

sketchybar --set "$NAME" drawing=on icon="$icon" label="$label"
