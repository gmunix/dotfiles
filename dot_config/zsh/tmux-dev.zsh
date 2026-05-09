tmux-dev() {
  local name="$1"
  local dev_dir="$2"

  if [ -z "$name" ]; then
    echo "Usage: tmux-dev <session-name> [path]" >&2
    return 1
  fi

  if ! tmux has-session -t "$name" 2>/dev/null; then
    tmux new-session -d -s "$name" -c "$dev_dir" -n editor "nvim"

    editor_pane="$(tmux display-message -p -t "${name}:editor.0" '#{pane_id}')"

    tmux split-window -t "$editor_pane" -h -c "$dev_dir" "opencode --port"
    tmux resize-pane -t "$editor_pane" -Z
    tmux select-pane -t "$editor_pane"

    tmux new-window -d -a -t "${name}:editor" -c "$dev_dir" -n shell
    tmux new-window -d -a -t "${name}:shell" -c "$dev_dir" -n git "lazygit"
    tmux select-window -t "${name}:nvim"
  fi

  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$name"
  else
    tmux attach-session -t "$name"
  fi
}
