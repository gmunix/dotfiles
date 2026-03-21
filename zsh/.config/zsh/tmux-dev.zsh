tmux-dev() {
  local name="$1"
  local dev_dir="$2"

  if [[ -z "$name" || -z "$dev_dir" ]]; then
    echo "Usage: tmux-dev <session-name> [path]" >&2
    return 1
  fi

  if ! tmux has-session -t "$name" 2>/dev/null; then
    tmux new-session -d -s "$name" -c "$dev_dir" -n nvim "nvim"
    tmux new-window -d -a -t "${name}:nvim" -c "$dev_dir" -n shell
    tmux new-window -d -a -t "${name}:shell" -c "$dev_dir" -n git "lazygit"
    tmux select-window -t "${name}:nvim"
  fi

  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$name"
  else
    tmux attach-session -t "$name"
  fi
}
