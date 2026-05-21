zettelkasten(){
  local name="zettelkasten"
  local notes_dir="$HOME/Notes/zettelkasten"

  if ! tmux has-session -t "$name" 2>/dev/null; then
    tmux new-session -d -c "$notes_dir" -s "$name" -n notes "nvim"
  fi

  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$name"
  else
    tmux attach-session -t "$name"
  fi
}
