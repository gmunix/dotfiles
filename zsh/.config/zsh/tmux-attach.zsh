tmux-attach(){
  local session=$(tmux ls -F "#{session_name}" | fzf)
  tmux attach -t $session
}
