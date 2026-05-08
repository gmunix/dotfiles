#!/usr/bin/env bash
set -euo pipefail

install=false
if [[ "${1:-}" == "--install" ]]; then
  install=true
fi

has() {
  command -v "$1" >/dev/null 2>&1
}

has_any() {
  local command_name
  for command_name in "$@"; do
    if has "$command_name"; then
      return 0
    fi
  done
  return 1
}

missing=()
recommended_missing=()

need() {
  local label="$1"
  local command_name="$2"
  if ! has "$command_name"; then
    missing+=("$label")
  fi
}

need_any() {
  local label="$1"
  shift
  if ! has_any "$@"; then
    missing+=("$label")
  fi
}

recommend() {
  local label="$1"
  local command_name="$2"
  if ! has "$command_name"; then
    recommended_missing+=("$label")
  fi
}

need "git" git
need_any "curl or wget" curl wget
need "unzip" unzip
need_any "tar or gtar" tar gtar
need "gzip" gzip
need "ripgrep" rg
need_any "C compiler" cc gcc clang
need_any "make" make gmake

recommend "node" node
recommend "npm" npm
recommend "python3" python3

if ((${#missing[@]} == 0)); then
  echo "Required Neovim OS dependencies are installed."
else
  echo "Missing required dependencies: ${missing[*]}"
fi

if ((${#recommended_missing[@]} > 0)); then
  echo "Missing recommended runtimes: ${recommended_missing[*]}"
fi

if [[ "$install" != true ]]; then
  echo "Run with --install to install common dependencies on supported systems."
  exit 0
fi

if has brew; then
  brew install git curl unzip gnu-tar gzip ripgrep node python@3
  if ! has_any cc gcc clang; then
    xcode-select --install || true
  fi
elif has apt-get; then
  sudo apt-get update
  sudo apt-get install -y git curl unzip tar gzip ripgrep nodejs npm python3 python3-venv build-essential
elif has pacman; then
  sudo pacman -S --needed git curl wget unzip tar gzip ripgrep nodejs npm python base-devel
elif has dnf; then
  sudo dnf install -y git curl wget unzip tar gzip ripgrep nodejs npm python3 python3-devel gcc gcc-c++ make
else
  echo "Unsupported package manager. Install the missing dependencies listed above."
  exit 1
fi
