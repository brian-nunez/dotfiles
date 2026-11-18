#!/usr/bin/env bash

alias gtg="gotogit"

goto() {
  local dir

  command -v fzf >/dev/null 2>&1 || return 127

  if [ -d "$HOME/workspace" ]; then
    dir=$(find "$HOME/workspace" -path "*/node_modules/*" -prune -o -type d -print | fzf)
    if [ -n "$dir" ]; then
      cd "$dir"
    fi
  fi
}

gotogit() {
  local dir search_dir

  command -v fzf >/dev/null 2>&1 || return 127

  search_dir="$HOME/workspace"
  if [ -n "${1:-}" ]; then
    search_dir="$1"
  fi

  if [ -d "$search_dir" ]; then
    dir=$(find "$search_dir" -path "*/node_modules" -prune -o -type d -name ".git" -print | sed 's|/\.git||' | fzf)
    if [ -n "$dir" ]; then
      cd "$dir"
    fi
  fi
}
