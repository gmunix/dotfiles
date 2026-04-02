GIT_BIN="$(command -v git 2>/dev/null || echo /usr/bin/git)"
CP_BIN="$(command -v cp 2>/dev/null || echo /bin/cp)"

worktree-list() {
  "$GIT_BIN" --git-dir="$MX_BARE" worktree list --porcelain \
    | awk '/^worktree /{print $2}' \
    | rg -v --fixed-strings "$HOME/Work/meetrox.git"
}

worktree-sync-backend-config() {
  local worktree_path="$1"
  local source_dir="$HOME/Work/env/chat-relay"
  local target_dir="$worktree_path/chat-relay/config"
  local -a source_files

  [ -d "$source_dir" ] || return 0
  [ -d "$target_dir" ] || return 0

  source_files=("$source_dir"/*(N.))
  [ "${#source_files[@]}" -eq 0 ] && return 0

  "$CP_BIN" -f "${source_files[@]}" "$target_dir"/
}

worktree-new() {
  local branch="$1"
  [ -z "$branch" ] && echo "usage: worktree-new <branch>" && return 1
  local path="$HOME/Work/meetrox-${branch//\//-}"

  if "$GIT_BIN" --git-dir="$MX_BARE" show-ref --verify --quiet "refs/heads/$branch"; then
    "$GIT_BIN" --git-dir="$MX_BARE" worktree add "$path" "$branch" || return 1
  else
    "$GIT_BIN" --git-dir="$MX_BARE" worktree add -b "$branch" "$path" main || return 1
  fi

  worktree-sync-backend-config "$path"
}

worktree-pane-dir() {
  local worktree_path="$1"
  local subdir="$2"
  local pane_path="${worktree_path}/${subdir}"

  if [ -d "$pane_path" ]; then
    printf "%s\n" "$pane_path"
  else
    printf "%s\n" "$worktree_path"
  fi
}

worktree-build-shell-layout() {
  local session_name="$1"
  local worktree_path="$2"
  local shell_window_target="${session_name}:shell"
  local editor_window_target="${session_name}:editor"
  local git_window_target="${session_name}:git"
  local env_path="$HOME/Work/env"
  local bottom_pane_percent=5
  local top_grid_lower_row_percent=80
  local backend_dir
  local vue_dir
  local relay_dir
  local connector_dir
  local top_left_pane
  local top_right_pane

  backend_dir="$(worktree-pane-dir "$worktree_path" "meetrox-backend")"
  vue_dir="$(worktree-pane-dir "$worktree_path" "meetrox-vue")"
  relay_dir="$(worktree-pane-dir "$worktree_path" "chat-relay")"
  connector_dir="$(worktree-pane-dir "$worktree_path" "whatsapp-connector")"

  # EDITOR
  tmux new-session -d -s "$session_name" -n code -c "$worktree_path" "nvim"

  editor_pane="$(tmux display-message -p -t "${session_name}:editor.0" '#{pane_id}')"
  tmux split-window -t "$editor_pane" -h -p 20 -c "$worktree_path" "opencode --port"
  tmux resize-pane -t "$editor_pane" -Z
  tmux select-pane -t "$editor_pane"

  # SHELL
  tmux new-window -t "$session_name" -n shell -c "$backend_dir"

  top_left_pane="$(tmux display-message -p -t "${shell_window_target}.0" '#{pane_id}')"
  tmux split-window -t "$top_left_pane" -v -p "$bottom_pane_percent" -c "$env_path" >/dev/null

  top_right_pane="$(tmux split-window -t "$top_left_pane" -h -p 50 -c "$vue_dir" -P -F '#{pane_id}')"
  tmux split-window -t "$top_left_pane"  -v -p "$top_grid_lower_row_percent" -c "$relay_dir" >/dev/null
  tmux split-window -t "$top_right_pane" -v -p "$top_grid_lower_row_percent" -c "$connector_dir" >/dev/null

  tmux select-pane -t "$top_left_pane"

  # GIT
  tmux new-window -t "$session_name" -n git -c "$worktree_path" "lazygit"

  lazygit_pane="$(tmux display-message -p -t "${git_window_target}.0" '#{pane_id}')"
  tmux split-window -t "$lazygit_pane" -v -c "$worktree_path"

  # Select main window
  tmux select-window -t "${session_name}:code"
}

worktree-open() {
  local worktree_path
  worktree_path="$(wl | fzf)" || return 1

  local session_name
  session_name="$(basename "$worktree_path" | tr '/.:' '___')"

  if ! tmux has-session -t "$session_name" 2>/dev/null; then
    worktree-build-shell-layout "$session_name" "$worktree_path"
  fi

  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$session_name"
  else
    tmux attach-session -t "$session_name"
  fi
}

worktree-delete() {
  local wt
  wt="$(wl | fzf)" || return 1

  printf "Delete worktree: %s? [y/N] " "$wt"
  read -r confirm
  case "$confirm" in
    y|Y)
      "$GIT_BIN" --git-dir="$MX_BARE" worktree remove "$wt"
      ;;
    *)
      echo "aborted"
      return 1
      ;;
  esac
}
