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
- Linux desktop applies Hyprland, SwayNC, and Waybar
- non-matching OS files are ignored through `.chezmoiignore`

Role controls how much of the setup is applied:

- `desktop` gets shared terminal/editor config plus GUI desktop packages/configs for the current OS, including Ghostty config
- `server` gets shared terminal/editor config and avoids GUI desktop packages/configs

Neovim's `lua/local/profile.lua` is generated per host from `[data.features.nvim]` in `~/.config/chezmoi/chezmoi.toml`. The default desktop profile enables optional UI/workflow plugins like Obsidian, Dadbod, REST, Windsurf, undo-glow, and Milli. The default server profile disables those heavier optional plugins while keeping core Neovim and Neogit enabled.

## Packages

Package declarations live in `.chezmoidata/package_catalog.yaml`.

The install script `.chezmoiscripts/run_onchange_10-install-packages.sh.tmpl` supports:

- Homebrew on macOS
- apt on Debian/Ubuntu-style Linux
- pacman on Arch-style Linux

Package groups are selected per host through `~/.config/chezmoi/chezmoi.toml`.

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
