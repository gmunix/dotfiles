# Dotfiles

These dotfiles are managed with [chezmoi](https://www.chezmoi.io/).

Managed files live in the `dot_*`, `dot_config`, `.chezmoidata`, and `.chezmoiscripts` paths.

## Current Machine Cutover

Install chezmoi if needed:

```sh
brew install chezmoi
```

Initialize chezmoi against this checked-out repo:

```sh
chezmoi --source "$PWD" init --promptDefaults
```

Preview changes:

```sh
chezmoi --source "$PWD" apply --dry-run --verbose
```

Apply changes:

```sh
chezmoi --source "$PWD" apply --verbose
```

Because this machine was previously stowed, the first apply replaces managed stow symlinks in `$HOME` with regular files/directories rendered by chezmoi.

The legacy stow directories have been removed. Rofi config is intentionally not migrated yet because the Linux desktop setup is expected to be overhauled, but related command dependencies are represented in the Linux desktop package group.

## New Machine

Install chezmoi into `~/.local/bin` first:

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
```

Then initialize and apply this repo:

```sh
~/.local/bin/chezmoi init --apply <repo-url>
```

For private repos, use the SSH URL:

```sh
~/.local/bin/chezmoi init --apply git@github.com:<user>/<repo>.git
```

During init, `.chezmoi.toml.tmpl` creates local machine data in `~/.config/chezmoi/chezmoi.toml`.

## Machine Data

Each machine has local data like this:

```toml
[data.machine]
role = "desktop" # desktop or server
desktopProfile = "none" # hyprland or none

[data.packages]
manager = "brew" # brew, apt, pacman, or none
groups = ["base", "nvim", "desktop", "macos-desktop"]
```

Servers should usually use:

```toml
[data.machine]
role = "server"

[data.packages]
manager = "apt"
groups = ["base", "nvim", "server"]
```

## Profiles

There is one chezmoi source tree, but it renders different results by OS and role.

OS controls platform-specific files:

- macOS desktop applies AeroSpace and SketchyBar
- Debian/Ubuntu-style Linux desktops use the generic Linux desktop package group
- Arch-style Linux desktops can select an explicit `hyprland` profile; generic Arch defaults to `none`
- CachyOS desktops default to the `hyprland` profile and add the CachyOS-packaged Noctalia shell when that default is accepted
- non-matching OS files are ignored through `.chezmoiignore`

Role controls how much of the setup is applied:

- `desktop` gets shared terminal/editor config plus GUI desktop packages for the current OS, including Ghostty config
- `server` gets shared terminal/editor config and avoids GUI desktop packages/configs

Neovim's `lua/local/profile.lua` is generated per host from `[data.features.nvim]` in `~/.config/chezmoi/chezmoi.toml`. The default desktop profile enables optional UI/workflow plugins like Obsidian, Dadbod, REST, Windsurf, undo-glow, and Milli. The default server profile disables those heavier optional plugins while keeping core Neovim and Neogit enabled.

## Appearance

Ghostty reads its font family, font size, and theme from `[data.appearance.ghostty]`. Portable profiles use the built-in `Gruvbox Dark Hard` theme, while the CachyOS Noctalia profile selects the generated `noctalia` theme. Until that custom theme file exists, the rendered config safely uses Gruvbox; run `chezmoi apply ~/.config/ghostty/config` after Noctalia generates it.

Neovim reads its theme from `[data.appearance.nvim]`. The `noctalia` profile loads Matugen colors through `base16-nvim` when the generated module is available and falls back to Monokai otherwise. Other profiles use Monokai directly.

Noctalia owns the dynamic files `~/.config/ghostty/themes/noctalia` and `~/.config/nvim/lua/matugen.lua`; chezmoi intentionally does not manage them.

## Packages

Package declarations live in `.chezmoidata/package_catalog.yaml`.

The install script `.chezmoiscripts/run_onchange_10-install-packages.sh.tmpl` supports:

- Homebrew on macOS
- apt on Debian/Ubuntu-style Linux
- pacman on Arch-style Linux

Package groups are selected per host through `~/.config/chezmoi/chezmoi.toml`.
Known operating systems select their package manager automatically during initialization. Unknown Linux distributions prompt for `apt`, `pacman`, or the safe `none` default.

### Existing Linux Machines

Machine data generated before desktop profiles were introduced must be migrated in `~/.config/chezmoi/chezmoi.toml` before package scripts can run:

- set `[data.packages].manager` to `pacman` on Arch/CachyOS or `apt` on Debian/Ubuntu
- add `desktopProfile = "hyprland"` or `desktopProfile = "none"` under `[data.machine]`
- for Hyprland, add `arch-hyprland` to `[data.packages].groups` and keep `[data.features].hyprland = true`
- on CachyOS with Noctalia, also add `cachyos-noctalia` and keep `[data.features].noctalia = true`
- on generic Arch, set `[data.features].noctalia = false` and do not select `cachyos-noctalia`

Inconsistent legacy profiles are ignored for Hyprland/Noctalia file application, and the package script rejects them with migration guidance. Pacman provisioning also requires `checkupdates` and `fakeroot`; install them with `sudo pacman -Syu pacman-contrib fakeroot` before the first package run if necessary.

Run dependency installation explicitly with:

```sh
chezmoi apply --include scripts --verbose
```

## Daily Use

Preview local changes:

```sh
chezmoi diff
```

Apply local source changes:

```sh
chezmoi apply --verbose
```

Pull and apply remote changes:

```sh
chezmoi update --verbose
```

Edit a managed target:

```sh
chezmoi edit ~/.config/nvim/init.lua
```
