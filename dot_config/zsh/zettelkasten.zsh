zettelkasten(){
  local name="zettelkasten"
  local notes_dir="$HOME/Notes/zettelkasten"

  if ! tmux has-session -t "$name" 2>/dev/null; then
    tmux new-session -d -c "$notes_dir" -s "$name" -n notes "nvim"

    local editor_pane="$(tmux display-message -p -t "${name}:notes.0" '#{pane_id}')"

    tmux split-window -t "$editor_pane" -p 20 -h -c "$notes_dir" "opencode --port"
    tmux resize-pane -t "$editor_pane" -Z
    tmux select-pane -t "$editor_pane"
  fi

  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$name"
  else
    tmux attach-session -t "$name"
  fi
}
