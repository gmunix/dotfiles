#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ghostty_template="$repo_root/dot_config/ghostty/config.tmpl"
nvim_profile_template="$repo_root/dot_config/nvim/lua/local/profile.lua.tmpl"
nvim_theme_spec="$repo_root/dot_config/nvim/lua/plugins/ui/theme.lua"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
empty_config="$tmp_dir/empty.toml"
: >"$empty_config"
source_config="$tmp_dir/source.toml"
printf 'sourceDir = "%s"\n' "$repo_root" >"$source_config"

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

noctalia_home="$tmp_dir/noctalia-home"
mkdir -p "$noctalia_home/.config/ghostty/themes"
cat >"$noctalia_home/.config/ghostty/themes/noctalia" <<'GHOSTTY_THEME'
background = #131313
foreground = #e2e2e2
GHOSTTY_THEME

current_ghostty="$tmp_dir/current-ghostty.conf"
first_boot_ghostty="$tmp_dir/first-boot-ghostty.conf"
fallback_ghostty="$tmp_dir/fallback-ghostty.conf"
current_data=$(printf '{"appearance":{"ghostty":{"fontFamily":"CaskaydiaMono Nerd Font","fontSize":11,"theme":"noctalia"}},"chezmoi":{"os":"linux","homeDir":"%s"}}' "$noctalia_home")
first_boot_data=$(printf '{"appearance":{"ghostty":{"theme":"noctalia"}},"chezmoi":{"os":"linux","homeDir":"%s"}}' "$tmp_dir/first-boot-home")
chezmoi --config "$empty_config" execute-template --override-data "$current_data" \
	-f "$ghostty_template" >"$current_ghostty"
chezmoi --config "$empty_config" execute-template --override-data "$first_boot_data" \
	-f "$ghostty_template" >"$first_boot_ghostty"
chezmoi --config "$empty_config" execute-template \
	--override-data '{"appearance":{"ghostty":{"fontFamily":"JetBrainsMono Nerd Font","fontSize":14,"theme":"Gruvbox Dark Hard"}},"chezmoi":{"os":"darwin"}}' \
	-f "$ghostty_template" >"$fallback_ghostty"
chezmoi --config "$empty_config" execute-template -f "$ghostty_template" >"$tmp_dir/default-ghostty.conf"

current_config=$(<"$current_ghostty")
[[ $current_config == *'theme = noctalia'* ]] || fail "Current Ghostty theme was not rendered in Noctalia's canonical form"
[[ $current_config == *'font-family = "CaskaydiaMono Nerd Font"'* ]] || fail "Current Ghostty font was not rendered"
[[ $current_config == *'font-size = 11'* ]] || fail "Current Ghostty font size was not rendered"
[[ $current_config != *'macos-titlebar-style'* ]] || fail "macOS titlebar setting was rendered on Linux"
[[ $(<"$first_boot_ghostty") == *'theme = "Gruvbox Dark Hard"'* ]] || fail "First-boot Ghostty config did not fall back to a built-in theme"
[[ $(<"$tmp_dir/default-ghostty.conf") == *'theme = "Gruvbox Dark Hard"'* ]] || fail "Missing Ghostty appearance data did not use defaults"

fallback_config=$(<"$fallback_ghostty")
[[ $fallback_config == *'theme = "Gruvbox Dark Hard"'* ]] || fail "Fallback Ghostty theme was not rendered"
[[ $fallback_config == *'font-family = "JetBrainsMono Nerd Font"'* ]] || fail "Fallback Ghostty font was not rendered"
[[ $fallback_config == *'font-size = 14'* ]] || fail "Fallback Ghostty font size was not rendered"
[[ $fallback_config == *'macos-titlebar-style = "hidden"'* ]] || fail "macOS titlebar setting was not rendered"

if command -v ghostty >/dev/null 2>&1; then
	ghostty +validate-config --config-file="$fallback_ghostty"
	ghostty +validate-config --config-file="$first_boot_ghostty"
	XDG_CONFIG_HOME="$noctalia_home/.config" ghostty +validate-config --config-file="$current_ghostty"
else
	printf 'SKIP: Ghostty runtime validation (ghostty not installed).\n'
fi

ghostty_hook=/usr/share/noctalia/assets/templates/ghostty/apply.sh
if [[ -x $ghostty_hook ]]; then
	mock_bin="$tmp_dir/hook-bin"
	mkdir "$mock_bin"
	cat >"$mock_bin/pgrep" <<'MOCK_PGREP'
#!/usr/bin/env bash
exit 1
MOCK_PGREP
	cat >"$mock_bin/pkill" <<'MOCK_PKILL'
#!/usr/bin/env bash
exit 0
MOCK_PKILL
	chmod +x "$mock_bin/pgrep" "$mock_bin/pkill"
	cp "$current_ghostty" "$noctalia_home/.config/ghostty/config"
	cp "$current_ghostty" "$tmp_dir/ghostty-before-hook.conf"
	XDG_CONFIG_HOME="$noctalia_home/.config" PATH="$mock_bin:$PATH" "$ghostty_hook"
	cmp -s "$tmp_dir/ghostty-before-hook.conf" "$noctalia_home/.config/ghostty/config" || fail "Noctalia rewrote the managed Ghostty config"
else
	printf 'SKIP: Noctalia Ghostty hook compatibility (hook not installed).\n'
fi

chezmoi --config "$empty_config" execute-template --override-data '{"appearance":{"nvim":{"theme":"noctalia"}}}' -f "$nvim_profile_template" >"$tmp_dir/noctalia-profile.lua"
chezmoi --config "$empty_config" execute-template --override-data '{"appearance":{"nvim":{"theme":"monokai"}}}' -f "$nvim_profile_template" >"$tmp_dir/monokai-profile.lua"
chezmoi --config "$empty_config" execute-template -f "$nvim_profile_template" >"$tmp_dir/default-profile.lua"
luac -p "$tmp_dir/noctalia-profile.lua" "$tmp_dir/monokai-profile.lua" "$tmp_dir/default-profile.lua" "$nvim_theme_spec"
[[ $(<"$tmp_dir/noctalia-profile.lua") == *'theme = "noctalia"'* ]] || fail "Noctalia Neovim profile was not rendered"
[[ $(<"$tmp_dir/monokai-profile.lua") == *'theme = "monokai"'* ]] || fail "Monokai Neovim profile was not rendered"
[[ $(<"$tmp_dir/default-profile.lua") == *'theme = "monokai"'* ]] || fail "Missing Neovim appearance data did not use defaults"

chezmoi --config "$empty_config" execute-template --init \
	--override-data '{"role":"desktop","desktopProfile":"hyprland","chezmoi":{"os":"linux","osRelease":{"id":"cachyos","idLike":"arch"}}}' \
	-f "$repo_root/.chezmoi.toml.tmpl" >"$tmp_dir/cachyos.toml"
python - "$tmp_dir/cachyos.toml" <<'PYTHON'
import sys
import tomllib

with open(sys.argv[1], "rb") as config_file:
    appearance = tomllib.load(config_file)["data"]["appearance"]

assert appearance["ghostty"]["theme"] == "noctalia"
assert appearance["nvim"]["theme"] == "noctalia"
PYTHON

monokai_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/monokai-pro.nvim"
base16_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/base16-nvim"
if command -v nvim >/dev/null 2>&1 && [[ -d $monokai_dir && -d $base16_dir ]]; then
	for mode in monokai fallback corrupt setup-error dynamic; do
		THEME_MODE="$mode" THEME_SPEC="$nvim_theme_spec" nvim --headless -u NONE \
			--cmd "set runtimepath+=$monokai_dir" \
			--cmd "set runtimepath+=$base16_dir" \
			'+lua local mode=vim.env.THEME_MODE; package.loaded["core.profile"]={get=function() return mode == "monokai" and "monokai" or "noctalia" end}; if mode == "fallback" then package.preload["matugen"]=function() error("missing generated theme") end elseif mode == "corrupt" then package.preload["matugen"]=function() return true end elseif mode == "setup-error" then package.preload["matugen"]=function() return {setup=function() error("invalid generated theme") end} end elseif mode == "dynamic" then package.preload["matugen"]=function() return {setup=function() local colors={}; for index=0,15 do colors[("base%02X"):format(index)]="#131313" end; colors.base05="#e2e2e2"; require("base16-colorscheme").setup(colors) end} end end; local spec=dofile(vim.env.THEME_SPEC); spec.config(); if mode == "dynamic" then local normal=vim.api.nvim_get_hl(0,{name="Normal",link=false}); assert(normal.bg == tonumber("131313",16)) else assert(vim.g.colors_name == "monokai-pro") end' \
			+qa
	done
else
	printf 'SKIP: Neovim runtime theme validation (nvim or locked theme plugins not installed).\n'
fi

managed_files=$(chezmoi --config "$source_config" managed)
[[ $managed_files != *'.config/ghostty/themes/noctalia'* ]] || fail "Generated Ghostty theme is managed by chezmoi"
[[ $managed_files != *'.config/nvim/lua/matugen.lua'* ]] || fail "Generated Neovim theme is managed by chezmoi"

printf 'Appearance profile tests passed.\n'
