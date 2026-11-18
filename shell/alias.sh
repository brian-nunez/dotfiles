#!/usr/bin/env bash

if [ -n "${ZSH_VERSION:-}" ]; then
  alias s='source "$HOME/.zshrc"'
elif [ -n "${BASH_VERSION:-}" ]; then
  alias s='source "$HOME/.bashrc"'
fi

# Use NeoVim with short-hand alias
alias vim='nvim'

if [ "${DOTFILES_TAILSCALE:-0}" = 1 ] && [ "$(uname -s)" = Darwin ]; then
  if [ -x "$HOME/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]; then
    alias tailscale='"$HOME/Applications/Tailscale.app/Contents/MacOS/Tailscale"'
  elif [ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]; then
    alias tailscale='/Applications/Tailscale.app/Contents/MacOS/Tailscale'
  fi
fi
