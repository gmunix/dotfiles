#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
autostart_template="$repo_root/dot_config/hypr/modules/autostart.lua.tmpl"
brightness_template="$repo_root/dot_config/noctalia/brightness.toml.tmpl"
hyprland_config="$repo_root/dot_config/hypr/hyprland.lua"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

empty_config="$tmp_dir/empty.toml"
: >"$empty_config"
source_config="$tmp_dir/source.toml"
printf 'sourceDir = "%s"\n' "$repo_root" >"$source_config"

chezmoi --config "$empty_config" execute-template --override-data '{"features":{"sunshine":true}}' -f "$autostart_template" >"$tmp_dir/autostart-sunshine.lua"
chezmoi --config "$empty_config" execute-template --override-data '{"features":{"sunshine":false}}' -f "$autostart_template" >"$tmp_dir/autostart-default.lua"
chezmoi --config "$empty_config" execute-template -f "$autostart_template" >"$tmp_dir/autostart-legacy.lua"

for rendered in "$tmp_dir"/autostart-*.lua; do
  luac -p "$rendered"
  [[ $(<"$rendered") == *'hl.exec_cmd(apps.noctalia)'* ]] || fail "Noctalia autostart was omitted"
done
[[ $(<"$tmp_dir/autostart-sunshine.lua") == *'app-dev.lizardbyte.app.Sunshine'* ]] || fail "Sunshine-enabled profile omitted its service"
[[ $(<"$tmp_dir/autostart-default.lua") != *'app-dev.lizardbyte.app.Sunshine'* ]] || fail "Sunshine-disabled profile started its service"
[[ $(<"$tmp_dir/autostart-legacy.lua") != *'app-dev.lizardbyte.app.Sunshine'* ]] || fail "Legacy profile did not default Sunshine off"

chezmoi --config "$empty_config" execute-template --override-data '{"features":{"ddcutil":true}}' -f "$brightness_template" >"$tmp_dir/brightness-ddc.toml"
chezmoi --config "$empty_config" execute-template --override-data '{"features":{"ddcutil":false}}' -f "$brightness_template" >"$tmp_dir/brightness-default.toml"
chezmoi --config "$empty_config" execute-template -f "$brightness_template" >"$tmp_dir/brightness-legacy.toml"
[[ $(<"$tmp_dir/brightness-ddc.toml") == *'enable_ddcutil = true'* ]] || fail "DDC-enabled profile was not rendered"
[[ $(<"$tmp_dir/brightness-default.toml") == *'enable_ddcutil = false'* ]] || fail "DDC-disabled profile was not rendered"
[[ $(<"$tmp_dir/brightness-legacy.toml") == *'enable_ddcutil = false'* ]] || fail "Legacy profile did not default DDC off"

luac -p "$hyprland_config"
[[ $(<"$hyprland_config") == *'require("noctalia")'* ]] || fail "Hyprland config omitted Noctalia's hook detection marker"
HYPRLAND_CONFIG="$hyprland_config" lua <<'LUA'
local modules = {
  "modules.monitors",
  "modules.environment",
  "modules.autostart",
  "modules.appearance",
  "modules.layouts",
  "modules.input",
  "modules.rules",
}

for _, name in ipairs(modules) do
  package.preload[name] = function()
    return {}
  end
end
package.preload["modules.apps"] = function()
  return {}
end
package.preload["modules.keybinds"] = function()
  return { setup = function() end }
end
package.preload["noctalia"] = function()
  error("generated module is not available yet")
end

dofile(os.getenv("HYPRLAND_CONFIG"))

package.loaded["noctalia"] = nil
package.preload["noctalia"] = function()
  return true
end
dofile(os.getenv("HYPRLAND_CONFIG"))

package.loaded["noctalia"] = nil
package.preload["noctalia"] = function()
  return { apply_theme = function() error("invalid generated theme") end }
end
dofile(os.getenv("HYPRLAND_CONFIG"))
LUA

hyprland_hook=/usr/share/noctalia/assets/templates/hyprland/apply.sh
if [[ -x $hyprland_hook ]]; then
  hook_home="$tmp_dir/hook-home"
  hook_bin="$tmp_dir/hook-bin"
  mkdir -p "$hook_home/.config/hypr" "$hook_bin"
  cp "$hyprland_config" "$hook_home/.config/hypr/hyprland.lua"
  cp "$hyprland_config" "$tmp_dir/hyprland-before-hook.lua"
  cat >"$hook_bin/hyprctl" <<'MOCK_HYPRCTL'
#!/usr/bin/env bash
exit 1
MOCK_HYPRCTL
  chmod +x "$hook_bin/hyprctl"
  HOME="$hook_home" XDG_CONFIG_HOME="$hook_home/.config" PATH="$hook_bin:$PATH" "$hyprland_hook" apply
  cmp -s "$tmp_dir/hyprland-before-hook.lua" "$hook_home/.config/hypr/hyprland.lua" || fail "Noctalia appended an unguarded Hyprland include"
else
  printf 'SKIP: Noctalia Hyprland hook compatibility (hook not installed).\n'
fi

arch_packages=$(chezmoi --config "$source_config" data --format=json | jq -r '.package_catalog.groups["arch-hyprland"].pacman[]')
[[ $arch_packages != *'waybar'* ]] || fail "Unused Waybar package remains in the Hyprland profile"
[[ $arch_packages != *'swaync'* ]] || fail "Unused SwayNC package remains in the Hyprland profile"

managed_files=$(chezmoi --config "$source_config" managed)
[[ $managed_files != *'.config/hypr/noctalia.lua'* ]] || fail "Generated Noctalia color module is managed by chezmoi"

printf 'Hyprland profile tests passed.\n'
