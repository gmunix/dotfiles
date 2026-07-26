#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmux_template="$repo_root/dot_tmux.conf.tmpl"
installer_template="$repo_root/.chezmoiscripts/run_onchange_after_30-install-tmux-plugins.sh.tmpl"
tmp_dir=$(mktemp -d)
socket="chezmoi-tmux-test-$$"
trap 'tmux -L "$socket" kill-server >/dev/null 2>&1 || true; rm -rf "$tmp_dir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

config_file="$tmp_dir/chezmoi.toml"
cat >"$config_file" <<EOF
sourceDir = "$repo_root"

[data.machine]
role = "server"
desktopProfile = "none"

[data.packages]
groups = []

[data.features]
hyprland = false
noctalia = false
spicetify = false
EOF
tmux -L "$socket" -f /dev/null new-session -d -s parser

render_tmux() {
  local data=$1
  local destination=$2
  chezmoi --config "$config_file" execute-template --override-data "$data" -f "$tmux_template" >"$destination"
  tmux -L "$socket" source-file -n "$destination"
}

render_installer() {
  local data=$1
  local destination=$2
  chezmoi --config "$config_file" execute-template --override-data "$data" -f "$installer_template" >"$destination"
  bash -n "$destination"
}

linux_home="$tmp_dir/linux-home"
macos_home="$tmp_dir/macos-home"
server_home="$tmp_dir/server-home"
linux_data=$(printf '{"appearance":{"tmux":{"theme":"gruvbox","plugins":true,"githubStatus":true}},"chezmoi":{"os":"linux","homeDir":"%s"}}' "$linux_home")
macos_data=$(printf '{"appearance":{"tmux":{"theme":"gruvbox","plugins":true,"githubStatus":false}},"chezmoi":{"os":"darwin","homeDir":"%s"}}' "$macos_home")
server_data=$(printf '{"appearance":{"tmux":{"theme":"gruvbox","plugins":false,"githubStatus":false}},"chezmoi":{"os":"linux","homeDir":"%s"}}' "$server_home")

render_tmux "$linux_data" "$tmp_dir/linux.conf"
render_tmux "$macos_data" "$tmp_dir/macos.conf"
render_tmux "$server_data" "$tmp_dir/server.conf"
chezmoi --config "$config_file" execute-template -f "$tmux_template" >"$tmp_dir/legacy.conf"
tmux -L "$socket" source-file -n "$tmp_dir/legacy.conf"

linux_config=$(<"$tmp_dir/linux.conf")
[[ $linux_config == *'set -g @plugin "tmux-plugins/tpm"'* ]] || fail "Linux desktop omitted TPM"
[[ $linux_config == *'set -g @plugin "adibhanna/gruvbox-tmux"'* ]] || fail "Linux desktop omitted its theme plugin"
[[ $linux_config == *'set -g @gruvbox-tmux_github_status on'* ]] || fail "Linux desktop did not enable GitHub status"
[[ $linux_config != *'/opt/homebrew/opt/bash/bin'* ]] || fail "Linux desktop rendered a Homebrew Bash path"
[[ $linux_config == *"TMUX_PLUGIN_MANAGER_PATH \"$linux_home/.tmux/plugins\""* ]] || fail "Linux desktop rendered the wrong plugin path"

macos_config=$(<"$tmp_dir/macos.conf")
[[ $macos_config == *'set -g @gruvbox-tmux_github_status off'* ]] || fail "macOS profile did not disable GitHub status"
[[ $macos_config == *'/opt/homebrew/opt/bash/bin'* ]] || fail "macOS profile omitted Apple Silicon Homebrew Bash"
[[ $macos_config == *'/usr/local/opt/bash/bin'* ]] || fail "macOS profile omitted Intel Homebrew Bash"

server_config=$(<"$tmp_dir/server.conf")
[[ $server_config != *'set -g @plugin'* ]] || fail "Plugin-disabled profile rendered plugins"
[[ $server_config != *'TMUX_PLUGIN_MANAGER_PATH'* ]] || fail "Plugin-disabled profile rendered a TPM path"
[[ $server_config != *'run-shell -b'* ]] || fail "Plugin-disabled profile initialized TPM"
[[ $(<"$tmp_dir/legacy.conf") != *'set -g @plugin'* ]] || fail "Legacy profile did not default plugins off"

chezmoi --config "$config_file" execute-template --init \
  --override-data '{"role":"desktop","desktopProfile":"hyprland","chezmoi":{"os":"linux","osRelease":{"id":"cachyos","idLike":"arch"}}}' \
  -f "$repo_root/.chezmoi.toml.tmpl" >"$tmp_dir/cachyos.toml"
chezmoi --config "$config_file" execute-template --init \
  --override-data '{"role":"desktop","packageManager":"none","chezmoi":{"os":"linux","osRelease":{"id":"fedora","idLike":""}}}' \
  -f "$repo_root/.chezmoi.toml.tmpl" >"$tmp_dir/unknown-linux.toml"
chezmoi --config "$config_file" execute-template --init \
  --override-data '{"role":"server","chezmoi":{"os":"linux","osRelease":{"id":"debian","idLike":""}}}' \
  -f "$repo_root/.chezmoi.toml.tmpl" >"$tmp_dir/server-machine.toml"
python - "$tmp_dir" <<'PYTHON'
import pathlib
import sys
import tomllib

root = pathlib.Path(sys.argv[1])


def plugins_enabled(name):
    with (root / name).open("rb") as config_file:
        return tomllib.load(config_file)["data"]["appearance"]["tmux"]["plugins"]


assert plugins_enabled("cachyos.toml") is True
assert plugins_enabled("unknown-linux.toml") is False
assert plugins_enabled("server-machine.toml") is False
PYTHON

last_line=$(awk 'NF { line=$0 } END { print line }' "$tmp_dir/linux.conf")
[[ $last_line == run-shell* ]] || fail "TPM initialization is not the final tmux command"

tmux -L "$socket" kill-server
mkdir -p "$linux_home/.tmux/plugins/tpm"
cat >"$linux_home/.tmux/plugins/tpm/tpm" <<'MOCK_RUNTIME_TPM'
#!/usr/bin/env bash
printf '%s\n' "$TMUX_PLUGIN_MANAGER_PATH" >"${TPM_RUNTIME_LOG:?}"
MOCK_RUNTIME_TPM
chmod +x "$linux_home/.tmux/plugins/tpm/tpm"
TPM_RUNTIME_LOG="$tmp_dir/runtime-tpm.log" tmux -L "$socket" -f "$tmp_dir/linux.conf" new-session -d -s profile-test
[[ $(tmux -L "$socket" show-option -gqv @gruvbox-tmux_github_status) == "on" ]] || fail "Rendered GitHub status was not applied"
[[ $(tmux -L "$socket" show-environment -g TMUX_PLUGIN_MANAGER_PATH | cut -d= -f2-) == "$linux_home/.tmux/plugins" ]] || fail "Rendered TPM path was not applied"
[[ $(<"$tmp_dir/runtime-tpm.log") == "$linux_home/.tmux/plugins" ]] || fail "TPM did not initialize synchronously from the canonical path"
tmux -L "$socket" kill-server

installer_home="$tmp_dir/installer-home"
enabled_installer_data=$(printf '{"appearance":{"tmux":{"theme":"gruvbox","plugins":true,"githubStatus":false}},"chezmoi":{"homeDir":"%s"}}' "$installer_home")
disabled_installer_data=$(printf '{"appearance":{"tmux":{"theme":"gruvbox","plugins":false,"githubStatus":false}},"chezmoi":{"homeDir":"%s"}}' "$installer_home")
render_installer "$enabled_installer_data" "$tmp_dir/install-enabled.sh"
render_installer "$disabled_installer_data" "$tmp_dir/install-disabled.sh"
[[ ! -s $tmp_dir/install-disabled.sh ]] || fail "Plugin-disabled profile rendered an installer"
installer_config=$(<"$tmp_dir/install-enabled.sh")
[[ $installer_config == *'# plugin: tmux-plugins/tpm'* ]] || fail "Installer signature omitted TPM"
[[ $installer_config == *'# plugin: adibhanna/gruvbox-tmux'* ]] || fail "Installer signature omitted the selected theme"

if unknown_output=$(chezmoi --config "$config_file" execute-template --override-data '{"appearance":{"tmux":{"theme":"unknown","plugins":true}}}' -f "$tmux_template" 2>&1); then
  fail "Unsupported tmux theme rendered successfully"
fi
[[ $unknown_output == *'unsupported tmux theme'* ]] || fail "Unsupported theme guidance was not emitted"
if chezmoi --config "$config_file" execute-template --override-data '{"appearance":{"tmux":{"theme":"unknown","plugins":false}}}' -f "$tmux_template" >/dev/null 2>&1; then
  fail "Plugin-disabled profile accepted an unsupported tmux theme"
fi

mock_bin="$tmp_dir/bin"
git_log="$tmp_dir/git.log"
mkdir "$mock_bin"
cat >"$mock_bin/git" <<'MOCK_GIT'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${GIT_LOG:?}"
if [[ ${1:-} == "-C" ]]; then
  directory=$2
  shift 2
  case "${1:-} ${2:-}" in
    "rev-parse HEAD")
      [[ -f $directory/.revision ]] || exit 1
      cat "$directory/.revision"
      ;;
    "status --porcelain")
      if [[ -f $directory/.dirty-tracked ]]; then
        printf ' M tracked-file\n'
      elif [[ -f $directory/.dirty-untracked ]]; then
        printf '?? untracked-file\n'
      fi
      ;;
    "checkout --detach")
      printf '%s\n' "$3" >"$directory/.revision"
      ;;
    *)
      exit 64
      ;;
  esac
  exit
fi
if [[ ${1:-} == "clone" ]]; then
  [[ ${MOCK_GIT_FAIL_CLONE:-0} != 1 ]] || exit 1
  url=${@: -2:1}
  target=${!#}
  mkdir -p "$target"
  printf '%s\n' "$url" >"$target/.url"
  if [[ $url == */tpm ]]; then
    cat >"$target/tpm" <<'MOCK_TPM'
#!/usr/bin/env bash
MOCK_TPM
    chmod +x "$target/tpm"
  fi
  exit
fi
exit 64
MOCK_GIT
chmod +x "$mock_bin/git"

plugin_root="$installer_home/.tmux/plugins"
mkdir -p "$plugin_root/tpm" "$plugin_root/tmux-floax" "$plugin_root/tmux-sessionx" "$plugin_root/gruvbox-tmux"
printf '%s\n' e261deb1b47614eed3400089ce7197dc68acc4eb >"$plugin_root/tpm/.revision"
printf '%s\n' 133f526793d90d2caa323c47687dd5544a2c704b >"$plugin_root/tmux-floax/.revision"
printf '%s\n' c9aaa1d309791871b5e8c1f9bfb91ecc5fa7da3a >"$plugin_root/tmux-sessionx/.revision"
printf '%s\n' c42019297da580017c0acc07a53b16de1660e3f6 >"$plugin_root/gruvbox-tmux/.revision"
cat >"$plugin_root/tpm/tpm" <<'MOCK_TPM'
#!/usr/bin/env bash
MOCK_TPM
chmod +x "$plugin_root/tpm/tpm"
: >"$git_log"
GIT_LOG="$git_log" HOME="$tmp_dir/runtime-home" PATH="$mock_bin:$PATH" bash "$tmp_dir/install-enabled.sh"
[[ $(<"$git_log") != *'clone '* ]] || fail "Pinned existing plugins were cloned again"

touch "$plugin_root/tpm/.dirty-tracked"
if dirty_tracked_output=$(GIT_LOG="$git_log" HOME="$tmp_dir/runtime-home" PATH="$mock_bin:$PATH" bash "$tmp_dir/install-enabled.sh" 2>&1); then
  fail "Tracked tmux plugin modifications were accepted"
fi
[[ $dirty_tracked_output == *'has local modifications'* ]] || fail "Tracked modification guidance was not emitted"
rm "$plugin_root/tpm/.dirty-tracked"

touch "$plugin_root/tpm/.dirty-untracked"
if dirty_untracked_output=$(GIT_LOG="$git_log" HOME="$tmp_dir/runtime-home" PATH="$mock_bin:$PATH" bash "$tmp_dir/install-enabled.sh" 2>&1); then
  fail "Untracked tmux plugin additions were accepted"
fi
[[ $dirty_untracked_output == *'has local modifications'* ]] || fail "Untracked modification guidance was not emitted"
rm "$plugin_root/tpm/.dirty-untracked"

rm -rf "$plugin_root"
mkdir -p "$plugin_root/tpm"
if invalid_output=$(GIT_LOG="$git_log" HOME="$tmp_dir/runtime-home" PATH="$mock_bin:$PATH" bash "$tmp_dir/install-enabled.sh" 2>&1); then
  fail "Invalid TPM installation did not fail"
fi
[[ $invalid_output == *'not a Git checkout'* ]] || fail "Invalid plugin guidance was not emitted"

rm -rf "$plugin_root"
mkdir -p "$plugin_root/tpm"
printf '%s\n' deadbeef >"$plugin_root/tpm/.revision"
if mismatch_output=$(GIT_LOG="$git_log" HOME="$tmp_dir/runtime-home" PATH="$mock_bin:$PATH" bash "$tmp_dir/install-enabled.sh" 2>&1); then
  fail "Mismatched pinned plugin revision did not fail"
fi
[[ $mismatch_output == *'Reconcile it manually and retry'* ]] || fail "Pinned revision guidance was not emitted"

rm -rf "$plugin_root"
: >"$git_log"
GIT_LOG="$git_log" HOME="$tmp_dir/runtime-home" TMUX_PLUGIN_MANAGER_PATH="$tmp_dir/wrong-path" PATH="$mock_bin:$PATH" bash "$tmp_dir/install-enabled.sh"
for plugin in tpm tmux-floax tmux-sessionx gruvbox-tmux; do
  [[ -f $plugin_root/$plugin/.revision ]] || fail "Pinned $plugin checkout was not installed"
done
[[ ! -e $tmp_dir/wrong-path ]] || fail "Installer honored a runtime-only plugin path override"
[[ $(<"$git_log") == *'clone --filter=blob:none --no-checkout https://github.com/tmux-plugins/tpm'* ]] || fail "Pinned TPM clone command was not used"

rm -rf "$plugin_root"
if offline_output=$(GIT_LOG="$git_log" MOCK_GIT_FAIL_CLONE=1 HOME="$tmp_dir/runtime-home" PATH="$mock_bin:$PATH" bash "$tmp_dir/install-enabled.sh" 2>&1); then
  fail "Offline plugin installation did not fail"
fi
[[ $offline_output == *'Check network access and retry'* ]] || fail "Offline retry guidance was not emitted"

managed_files=$(chezmoi --config "$config_file" managed)
[[ $managed_files != *'.config/theme/tmux-mac.conf'* ]] || fail "Removed macOS theme fragment is still managed"
[[ $managed_files != *'.config/theme/tmux-desktop.conf'* ]] || fail "Removed Linux theme fragment is still managed"

printf 'Tmux profile tests passed.\n'
