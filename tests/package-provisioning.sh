#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
config_template="$repo_root/.chezmoi.toml.tmpl"
installer_template="$repo_root/.chezmoiscripts/run_onchange_10-install-packages.sh.tmpl"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
fixture_config="$tmp_dir/chezmoi.toml"
printf 'sourceDir = "%s"\n' "$repo_root" >"$fixture_config"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

render_config() {
  local data=$1
  local destination=$2
  chezmoi --config "$fixture_config" execute-template --init --override-data "$data" -f "$config_template" >"$destination"
}

render_installer() {
  local data=$1
  local destination=$2
  chezmoi --config "$fixture_config" execute-template --override-data "$data" -f "$installer_template" >"$destination"
  bash -n "$destination"
}

render_config '{"role":"desktop","desktopProfile":"hyprland","chezmoi":{"os":"linux","osRelease":{"id":"cachyos","idLike":"arch"}}}' "$tmp_dir/cachyos.toml"
render_config '{"role":"desktop","desktopProfile":"none","chezmoi":{"os":"linux","osRelease":{"id":"arch","idLike":""}}}' "$tmp_dir/arch-none.toml"
render_config '{"role":"desktop","desktopProfile":"hyprland","chezmoi":{"os":"linux","osRelease":{"id":"arch","idLike":""}}}' "$tmp_dir/arch-hyprland.toml"
render_config '{"role":"desktop","chezmoi":{"os":"linux","osRelease":{"id":"debian","idLike":""}}}' "$tmp_dir/debian.toml"
render_config '{"role":"desktop","chezmoi":{"os":"darwin","arch":"arm64"}}' "$tmp_dir/macos.toml"
render_config '{"role":"desktop","packageManager":"none","chezmoi":{"os":"linux","osRelease":{"id":"fedora","idLike":""}}}' "$tmp_dir/unknown-linux.toml"

python - "$tmp_dir" <<'PYTHON'
import pathlib
import sys
import tomllib

root = pathlib.Path(sys.argv[1])


def load(name):
    with (root / name).open("rb") as config_file:
        return tomllib.load(config_file)["data"]


cachyos = load("cachyos.toml")
assert cachyos["packages"]["manager"] == "pacman"
assert cachyos["machine"]["desktopProfile"] == "hyprland"
assert "arch-hyprland" in cachyos["packages"]["groups"]
assert "cachyos-noctalia" in cachyos["packages"]["groups"]
assert cachyos["features"]["hyprland"] is True
assert cachyos["features"]["noctalia"] is True

arch_none = load("arch-none.toml")
assert arch_none["packages"]["manager"] == "pacman"
assert arch_none["machine"]["desktopProfile"] == "none"
assert "arch-hyprland" not in arch_none["packages"]["groups"]
assert "cachyos-noctalia" not in arch_none["packages"]["groups"]
assert arch_none["features"]["hyprland"] is False

arch_hyprland = load("arch-hyprland.toml")
assert arch_hyprland["machine"]["desktopProfile"] == "none"
assert "arch-hyprland" not in arch_hyprland["packages"]["groups"]
assert "cachyos-noctalia" not in arch_hyprland["packages"]["groups"]
assert arch_hyprland["features"]["hyprland"] is False
assert arch_hyprland["features"]["noctalia"] is False

debian = load("debian.toml")
assert debian["packages"]["manager"] == "apt"
assert debian["machine"]["desktopProfile"] == "none"
assert "arch-hyprland" not in debian["packages"]["groups"]

macos = load("macos.toml")
assert macos["packages"]["manager"] == "brew"
assert macos["machine"]["desktopProfile"] == "none"

unknown = load("unknown-linux.toml")
assert unknown["packages"]["manager"] == "none"
PYTHON

mock_bin="$tmp_dir/bin"
mkdir "$mock_bin"
command_log="$tmp_dir/commands.log"
live_db="$tmp_dir/live-db"
mkdir -p "$live_db/sync"
printf 'current database\n' >"$live_db/sync/core.db"

cat >"$mock_bin/pacman" <<'MOCK_PACMAN'
#!/usr/bin/env bash
printf 'pacman %s\n' "$*" >>"${COMMAND_LOG:?}"
case "${1:-}" in
  -Q)
    [[ ${PACMAN_SCENARIO:?} == "installed" ]]
    ;;
  -Si)
    [[ ${PACMAN_SCENARIO:?} != "unavailable" ]]
    ;;
  -S)
    ;;
  *)
    exit 64
    ;;
esac
MOCK_PACMAN

cat >"$mock_bin/pacman-conf" <<'MOCK_PACMAN_CONF'
#!/usr/bin/env bash
[[ ${1:-} == "DBPath" ]] || exit 64
printf '%s\n' "${PACMAN_LIVE_DB:?}"
MOCK_PACMAN_CONF

cat >"$mock_bin/checkupdates" <<'MOCK_CHECKUPDATES'
#!/usr/bin/env bash
printf 'checkupdates\n' >>"${COMMAND_LOG:?}"
mkdir -p "${CHECKUPDATES_DB:?}/sync"
case "${PACMAN_SCENARIO:?}" in
  upgrades)
    cp "${PACMAN_LIVE_DB:?}/sync/core.db" "$CHECKUPDATES_DB/sync/core.db"
    printf 'glibc 1-1 -> 1-2\n'
    ;;
  no-database)
    exit 2
    ;;
  stale)
    printf 'fresh database\n' >"$CHECKUPDATES_DB/sync/core.db"
    exit 2
    ;;
  check-failure)
    exit 1
    ;;
  *)
    cp "${PACMAN_LIVE_DB:?}/sync/core.db" "$CHECKUPDATES_DB/sync/core.db"
    exit 2
    ;;
esac
MOCK_CHECKUPDATES

cat >"$mock_bin/fakeroot" <<'MOCK_FAKEROOT'
#!/usr/bin/env bash
exec "$@"
MOCK_FAKEROOT

cat >"$mock_bin/sudo" <<'MOCK_SUDO'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >>"${COMMAND_LOG:?}"
exec "$@"
MOCK_SUDO
chmod +x "$mock_bin/pacman" "$mock_bin/pacman-conf" "$mock_bin/checkupdates" "$mock_bin/fakeroot" "$mock_bin/sudo"

installer_data='{"chezmoi":{"os":"linux","osRelease":{"id":"cachyos","idLike":"arch"}},"packages":{"manager":"pacman","groups":["arch-hyprland","cachyos-noctalia"]},"machine":{"desktopProfile":"hyprland"},"features":{"hyprland":true,"noctalia":true}}'
render_installer "$installer_data" "$tmp_dir/install-packages.sh"

run_installer() {
  local scenario=$1
  : >"$command_log"
  PATH="$mock_bin:$PATH" COMMAND_LOG="$command_log" PACMAN_LIVE_DB="$live_db" PACMAN_SCENARIO="$scenario" bash "$tmp_dir/install-packages.sh"
}

run_installer installed
installed_log=$(<"$command_log")
[[ $installed_log != *"checkupdates"* ]] || fail "Pacman freshness was checked with no pending packages"
[[ $installed_log != *"sudo "* ]] || fail "sudo was invoked with no pending packages"

if unavailable_output=$(run_installer unavailable 2>&1); then
  fail "Unavailable required packages did not fail"
fi
[[ $unavailable_output == *"Required Pacman packages are unavailable"* ]] || fail "Unavailable-package guidance was not emitted"
[[ $(<"$command_log") != *"sudo "* ]] || fail "sudo was invoked for an incomplete package set"

if upgrade_output=$(run_installer upgrades 2>&1); then
  fail "Pending system upgrades did not block package installation"
fi
[[ $upgrade_output == *"System upgrades are pending"* ]] || fail "Pending-upgrade guidance was not emitted"
[[ $(<"$command_log") != *"sudo "* ]] || fail "sudo was invoked while upgrades were pending"

if check_failure_output=$(run_installer check-failure 2>&1); then
  fail "A failed fresh upgrade check did not block package installation"
fi
[[ $check_failure_output == *"Unable to perform a fresh Pacman upgrade check"* ]] || fail "Freshness-check failure guidance was not emitted"
[[ $(<"$command_log") != *"sudo "* ]] || fail "sudo was invoked after a failed freshness check"

if database_output=$(run_installer no-database 2>&1); then
  fail "Missing sync databases did not block pending package installation"
fi
[[ $database_output == *"Pacman sync databases are unavailable"* ]] || fail "Missing-database guidance was not emitted"

if stale_output=$(run_installer stale 2>&1); then
  fail "Stale sync databases did not block package installation"
fi
[[ $stale_output == *"Pacman sync databases are stale"* ]] || fail "Stale-database guidance was not emitted"
[[ $(<"$command_log") != *"sudo "* ]] || fail "sudo was invoked with stale sync databases"

run_installer install
install_log=$(<"$command_log")
[[ $install_log == *"sudo pacman -S --needed --noconfirm"* ]] || fail "Expected guarded Pacman install was not invoked"
[[ $install_log != *"pacman -Sy "* ]] || fail "Unsafe pacman -Sy was invoked"
[[ $install_log != *"pacman -Syu"* ]] || fail "An implicit full upgrade was invoked"

legacy_data='{"packages":{"manager":"pacman","groups":["linux-desktop"]},"machine":{"desktopProfile":"none"},"features":{"hyprland":true,"noctalia":true}}'
render_installer "$legacy_data" "$tmp_dir/legacy-install.sh"
if legacy_output=$(PATH="$mock_bin:$PATH" COMMAND_LOG="$command_log" PACMAN_SCENARIO=installed bash "$tmp_dir/legacy-install.sh" 2>&1); then
  fail "An inconsistent legacy profile did not fail"
fi
[[ $legacy_output == *"desktop profile and [data.features].hyprland"* ]] || fail "Legacy profile migration guidance was not emitted"

inverse_data='{"packages":{"manager":"pacman","groups":["arch-hyprland"]},"machine":{"desktopProfile":"hyprland"},"features":{"hyprland":false,"noctalia":false}}'
render_installer "$inverse_data" "$tmp_dir/inverse-install.sh"
if inverse_output=$(PATH="$mock_bin:$PATH" COMMAND_LOG="$command_log" PACMAN_LIVE_DB="$live_db" PACMAN_SCENARIO=installed bash "$tmp_dir/inverse-install.sh" 2>&1); then
  fail "An inverse Hyprland profile mismatch did not fail"
fi
[[ $inverse_output == *"desktop profile and [data.features].hyprland"* ]] || fail "Inverse profile migration guidance was not emitted"

noctalia_mismatch_data='{"packages":{"manager":"pacman","groups":["arch-hyprland","cachyos-noctalia"]},"machine":{"desktopProfile":"hyprland"},"features":{"hyprland":true,"noctalia":false}}'
render_installer "$noctalia_mismatch_data" "$tmp_dir/noctalia-mismatch-install.sh"
if noctalia_output=$(PATH="$mock_bin:$PATH" COMMAND_LOG="$command_log" PACMAN_LIVE_DB="$live_db" PACMAN_SCENARIO=installed bash "$tmp_dir/noctalia-mismatch-install.sh" 2>&1); then
  fail "An inverse Noctalia group mismatch did not fail"
fi
[[ $noctalia_output == *"[data.features].hyprland and [data.features].noctalia"* ]] || fail "Hyprland/Noctalia invariant guidance was not emitted"

generic_arch_noctalia_data='{"chezmoi":{"os":"linux","osRelease":{"id":"arch","idLike":""}},"packages":{"manager":"pacman","groups":["arch-hyprland","cachyos-noctalia"]},"machine":{"desktopProfile":"hyprland"},"features":{"hyprland":true,"noctalia":true}}'
render_installer "$generic_arch_noctalia_data" "$tmp_dir/generic-arch-noctalia-install.sh"
if generic_arch_output=$(PATH="$mock_bin:$PATH" COMMAND_LOG="$command_log" PACMAN_LIVE_DB="$live_db" PACMAN_SCENARIO=installed bash "$tmp_dir/generic-arch-noctalia-install.sh" 2>&1); then
  fail "Generic Arch accepted the CachyOS-only Noctalia profile"
fi
[[ $generic_arch_output == *"supported only on CachyOS"* ]] || fail "Generic Arch Noctalia guidance was not emitted"

legacy_data='{"chezmoi":{"os":"linux","osRelease":{"id":"arch","idLike":""}},"packages":{"manager":"pacman","groups":["linux-desktop"]},"machine":{"desktopProfile":"none"},"features":{"hyprland":true,"noctalia":true}}'
legacy_ignore=$(chezmoi --config "$fixture_config" execute-template --override-data "$legacy_data" -f "$repo_root/.chezmoiignore")
[[ $legacy_ignore == *".config/hypr"* ]] || fail "Legacy Hyprland config was not ignored"
[[ $legacy_ignore == *".config/noctalia"* ]] || fail "Legacy Noctalia config was not ignored"

valid_ignore_data='{"chezmoi":{"os":"linux","osRelease":{"id":"cachyos","idLike":"arch"}},"packages":{"manager":"pacman","groups":["arch-hyprland","cachyos-noctalia"]},"machine":{"role":"desktop","desktopProfile":"hyprland"},"features":{"hyprland":true,"noctalia":true}}'
valid_ignore=$(chezmoi --config "$fixture_config" execute-template --override-data "$valid_ignore_data" -f "$repo_root/.chezmoiignore")
[[ $valid_ignore != *".config/hypr"* ]] || fail "A valid CachyOS Hyprland profile was ignored"
[[ $valid_ignore != *".config/noctalia"* ]] || fail "A valid CachyOS Noctalia profile was ignored"

partial_features_data='{"chezmoi":{"os":"linux","osRelease":{"id":"cachyos","idLike":"arch"}},"packages":{"groups":["arch-hyprland","cachyos-noctalia"]},"machine":{"role":"desktop","desktopProfile":"hyprland"},"features":{"hyprland":true,"noctalia":false}}'
partial_features_ignore=$(chezmoi --config "$fixture_config" execute-template --override-data "$partial_features_data" -f "$repo_root/.chezmoiignore")
[[ $partial_features_ignore == *".config/hypr"* ]] || fail "Partial CachyOS features did not ignore Hyprland"
[[ $partial_features_ignore == *".config/noctalia"* ]] || fail "Partial CachyOS features did not ignore Noctalia"

partial_groups_data='{"chezmoi":{"os":"linux","osRelease":{"id":"cachyos","idLike":"arch"}},"packages":{"groups":["arch-hyprland"]},"machine":{"role":"desktop","desktopProfile":"hyprland"},"features":{"hyprland":true,"noctalia":true}}'
partial_groups_ignore=$(chezmoi --config "$fixture_config" execute-template --override-data "$partial_groups_data" -f "$repo_root/.chezmoiignore")
[[ $partial_groups_ignore == *".config/hypr"* ]] || fail "Partial CachyOS groups did not ignore Hyprland"
[[ $partial_groups_ignore == *".config/noctalia"* ]] || fail "Partial CachyOS groups did not ignore Noctalia"

managed_files=$(chezmoi --config "$fixture_config" managed)
[[ $managed_files != *"tests/package-provisioning.sh"* ]] || fail "Source-only tests are managed as home files"

chezmoi --config "$fixture_config" execute-template -f "$repo_root/.chezmoiignore" >"$tmp_dir/empty-profile.ignore"
[[ $(<"$tmp_dir/empty-profile.ignore") == *".config/hypr"* ]] || fail "Missing machine data did not fail closed"
chezmoi --config "$fixture_config" execute-template -f "$installer_template" >"$tmp_dir/empty-profile-installer.sh"
[[ ! -s $tmp_dir/empty-profile-installer.sh ]] || fail "Missing package data rendered an installer"

if grep -Eq 'sudo pacman -Sy([[:space:]]|$)' "$installer_template"; then
  fail "Installer template contains unsafe pacman -Sy"
fi

printf 'Package provisioning tests passed.\n'
