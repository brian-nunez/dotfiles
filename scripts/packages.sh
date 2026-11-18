#!/usr/bin/env bash
set -euo pipefail
DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
. "$DOTFILES_ROOT/scripts/profile.sh"
dotfiles_load_profile "${1:?Profile required}"
apply=0
case "${2:-}" in '') ;; --apply) apply=1 ;; *) exit 1 ;; esac
formulae=(git neovim tmux fzf go node)
casks=(ghostty font-jetbrains-mono-nerd-font)
arch=(git neovim tmux fzf go nodejs npm ghostty ttf-jetbrains-mono-nerd)
if [ "$DOTFILES_JAVA" = 1 ]; then formulae+=(openjdk@21); arch+=(jdk21-openjdk); fi
if [ "$DOTFILES_RUBY" = 1 ]; then formulae+=(rbenv ruby-build); arch+=(rbenv ruby-build); fi
if [ "$DOTFILES_ARDUINO" = 1 ]; then formulae+=(arduino-cli); arch+=(arduino-cli); fi
if [ "$DOTFILES_DOCKER" = 1 ]; then formulae+=(docker docker-compose); arch+=(docker docker-compose); fi
if [ "$DOTFILES_TAILSCALE" = 1 ]; then casks+=(tailscale-app); arch+=(tailscale); fi
run() {
  printf '%q ' "$@"; printf '\n'
  if [ "$apply" = 1 ]; then "$@"; fi
}
case "$DOTFILES_PLATFORM:$(uname -s):$(uname -m)" in
  macos:Darwin:arm64)
    if [ -x /opt/homebrew/bin/brew ]; then export PATH="/opt/homebrew/bin:$PATH"; fi
    if [ "$apply" = 1 ] && ! command -v brew >/dev/null; then
      echo 'Homebrew required. On a work Mac, ask IT to provision a writable /opt/homebrew and Xcode Command Line Tools.' >&2; exit 1
    fi
    run brew install "${formulae[@]}"
    run brew install --cask --appdir="$HOME/Applications" "${casks[@]}"
    ;;
  omarchy:Linux:x86_64) run sudo pacman -S --needed "${arch[@]}" ;;
  *) echo 'Profile does not match host.' >&2; exit 1 ;;
esac
