tmux-dev() {
  local name="$1"

  if [ -z "$name" ]; then
    echo "Usage: tmux-dev <session-name>" >&2
    return 1
  fi

  if ! tmux has-session -t "$name" 2>/dev/null; then
    tmux new-session -d -s "$name" -n nvim "nvim"
    tmux new-window -d -a -t "${name}:nvim" -n shell
    tmux new-window -d -a -t "${name}:shell" -n git "lazygit"
    tmux select-window -t "${name}:nvim"
  fi

  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$name"
  else
    tmux attach-session -t "$name"
  fi
}
