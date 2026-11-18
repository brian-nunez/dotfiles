#!/usr/bin/env bash

alias gtg="gotogit"

GOTO_IGNORE_DIRS=(
  # VCS
  .git .hg .svn
  # JavaScript / TypeScript
  node_modules bower_components .next .nuxt .svelte-kit .turbo .parcel-cache
  .yarn .pnpm-store .angular .expo coverage .nyc_output
  # Python
  .venv venv __pycache__ .mypy_cache .pytest_cache .ruff_cache .tox .nox
  .eggs .ipynb_checkpoints
  # Build output / dependency caches
  dist build out target vendor .gradle .terraform .direnv .cache
  # Apple / mobile
  Pods DerivedData .build
  # Editors
  .idea .vscode-test
)

goto() {
  local dir name
  local -a prune_args

  command -v fzf >/dev/null 2>&1 || return 127

  for name in "${GOTO_IGNORE_DIRS[@]}"; do
    if [ ${#prune_args[@]} -gt 0 ]; then
      prune_args+=(-o)
    fi
    prune_args+=(-name "$name")
  done

  if [ -d "${WORKSPACE_DIR:-$HOME/Documents/workspace}" ]; then
    dir=$(find "${WORKSPACE_DIR:-$HOME/Documents/workspace}" \
      -type d \( "${prune_args[@]}" \) -prune \
      -o -type d -print | fzf)

    if [ -n "$dir" ]; then
      cd "$dir"
    fi
  fi
}

gotogit() {
  local dir search_dir

  command -v fzf >/dev/null 2>&1 || return 127

  search_dir="${WORKSPACE_DIR:-$HOME/Documents/workspace}"
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

echo "✅ Initialized Search Helpers"
