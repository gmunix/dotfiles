#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
starship_template="$repo_root/.chezmoiscripts/run_onchange_15-configure-starship.sh.tmpl"
spicetify_template="$repo_root/.chezmoiscripts/run_onchange_20-configure-spicetify.sh.tmpl"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

empty_config="$tmp_dir/empty.toml"
: >"$empty_config"
chezmoi --config "$empty_config" execute-template -f "$starship_template" >"$tmp_dir/configure-starship.sh"
bash -n "$tmp_dir/configure-starship.sh"

mock_bin="$tmp_dir/bin"
mkdir "$mock_bin"
cat >"$mock_bin/starship" <<'MOCK_STARSHIP'
#!/usr/bin/env bash
printf '%s|%s\n' "${STARSHIP_CONFIG:?}" "$*" >>"${STARSHIP_LOG:?}"
touch "$STARSHIP_CONFIG"
MOCK_STARSHIP
chmod +x "$mock_bin/starship"

run_starship_case() {
  local name=$1
  local expected=$2
  shift 2
  local home="$tmp_dir/$name-home"
  local log="$tmp_dir/$name.log"
  mkdir -p "$home"
  env HOME="$home" PATH="$mock_bin:$PATH" STARSHIP_LOG="$log" "$@" bash "$tmp_dir/configure-starship.sh"
  [[ -f $expected ]] || fail "$name Starship config was not created"
  local output
  output=$(<"$log")
  [[ $output == *"$expected|config username.disabled true"* ]] || fail "$name username config used the wrong path"
  [[ $output == *"$expected|config hostname.disabled true"* ]] || fail "$name hostname config used the wrong path"
}

default_home="$tmp_dir/default-home"
run_starship_case default "$default_home/.config/starship.toml"

xdg_home="$tmp_dir/xdg-home"
xdg_config="$tmp_dir/custom-xdg"
run_starship_case xdg "$xdg_config/starship.toml" env XDG_CONFIG_HOME="$xdg_config"

explicit_home="$tmp_dir/explicit-home"
explicit_config="$tmp_dir/explicit/config/starship.toml"
run_starship_case explicit "$explicit_config" env STARSHIP_CONFIG="$explicit_config"

marker_config="$tmp_dir/marker/starship.toml"
mkdir -p "${marker_config%/*}"
cat >"$marker_config" <<'STARSHIP_CONFIG'
# >>> NOCTALIA STARSHIP PALETTE >>>
palette = "noctalia"
[username]
disabled = false
STARSHIP_CONFIG
STARSHIP_CONFIG="$marker_config" STARSHIP_LOG="$tmp_dir/marker.log" PATH="$mock_bin:$PATH" bash "$tmp_dir/configure-starship.sh"
first_marker_result=$(<"$marker_config")
[[ $first_marker_result == *'# <<< NOCTALIA STARSHIP PALETTE <<<'* ]] || fail "Starship marker was not closed"
STARSHIP_CONFIG="$marker_config" STARSHIP_LOG="$tmp_dir/marker.log" PATH="$mock_bin:$PATH" bash "$tmp_dir/configure-starship.sh"
[[ $(<"$marker_config") == "$first_marker_result" ]] || fail "Starship marker migration was not idempotent"

missing_bin="$tmp_dir/missing-bin"
mkdir "$missing_bin"
if ! missing_output=$(PATH="$missing_bin" /usr/bin/bash "$tmp_dir/configure-starship.sh" 2>&1); then
  fail "Missing Starship binary returned failure"
fi
[[ $missing_output == *'Starship is not installed'* ]] || fail "Missing Starship guidance was not emitted"

enabled_data='{"chezmoi":{"os":"linux"},"machine":{"role":"desktop"},"features":{"spicetify":true}}'
disabled_data='{"chezmoi":{"os":"linux"},"machine":{"role":"desktop"},"features":{"spicetify":false}}'
chezmoi --config "$empty_config" execute-template --override-data "$enabled_data" -f "$spicetify_template" >"$tmp_dir/configure-spicetify.sh"
chezmoi --config "$empty_config" execute-template --override-data "$disabled_data" -f "$spicetify_template" >"$tmp_dir/disabled-spicetify.sh"
bash -n "$tmp_dir/configure-spicetify.sh"
[[ $(<"$tmp_dir/disabled-spicetify.sh") != *'#!/usr/bin/env bash'* ]] || fail "Disabled Spicetify profile rendered an installer"

cat >"$mock_bin/spicetify" <<'MOCK_SPICETIFY'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${SPICETIFY_LOG:?}"
MOCK_SPICETIFY
chmod +x "$mock_bin/spicetify"
spicetify_home="$tmp_dir/spicetify-home"
mkdir "$spicetify_home"
SPICETIFY_LOG="$tmp_dir/spicetify.log" HOME="$spicetify_home" PATH="$mock_bin:$PATH" bash "$tmp_dir/configure-spicetify.sh"
spicetify_log=$(<"$tmp_dir/spicetify.log")
[[ $spicetify_log == *'config current_theme Colorful color_scheme noctalia'* ]] || fail "Spicetify theme command was incorrect"
[[ $spicetify_log == *'config inject_css 1 replace_colors 1 overwrite_assets 1 inject_theme_js 1'* ]] || fail "Spicetify injection command was incorrect"
[[ $spicetify_log == *'apply'* ]] || fail "Spicetify apply command was omitted"

missing_spicetify_home="$tmp_dir/missing-spicetify-home"
mkdir "$missing_spicetify_home"
if ! missing_spicetify_output=$(HOME="$missing_spicetify_home" PATH="$missing_bin" /usr/bin/bash "$tmp_dir/configure-spicetify.sh" 2>&1); then
  fail "Missing Spicetify binary returned failure"
fi
[[ $missing_spicetify_output == *'Spicetify is not installed'* ]] || fail "Missing Spicetify guidance was not emitted"

printf 'Integration script tests passed.\n'
