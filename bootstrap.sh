#!/usr/bin/env bash
set -euo pipefail
DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export DOTFILES_ROOT
. "$DOTFILES_ROOT/scripts/profile.sh"
usage() {
  echo 'Usage: ./bootstrap.sh PROFILE [--apply] [--backup] [--packages] [--migrate-shell]'
  echo 'Profiles: omarchy, mac-personal, mac-work. Default: preview only.'
}
[ "$#" -gt 0 ] || { usage; exit 1; }
profile=$1; shift
apply=0; backup=0; packages=0; migrate_shell=0
for arg in "$@"; do
  case "$arg" in --apply) apply=1 ;; --backup) backup=1 ;; --packages) packages=1 ;; --migrate-shell) migrate_shell=1 ;; *) usage; exit 1 ;; esac
done
dotfiles_load_profile "$profile"
case "$DOTFILES_PLATFORM:$(uname -s):$(uname -m)" in
  omarchy:Linux:x86_64)
    [ -d /usr/share/omarchy ] || [ -d "$HOME/.local/share/omarchy" ] || { echo 'Omarchy installation not found.' >&2; exit 1; } ;;
  macos:Darwin:arm64) ;;
  *) echo 'Selected profile does not match this machine.' >&2; exit 1 ;;
esac
backup_root="$HOME/.local/state/dotfiles/backups/$(date +%Y%m%dT%H%M%S)-$$"
# Build the complete operation list before changing any destination.
sources=(); targets=(); contents=()
add_link() { sources+=("$1"); targets+=("$2"); contents+=(''); }
add_file() { sources+=(''); targets+=("$1"); contents+=("$2"); }
add_link "$DOTFILES_ROOT/config/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
ghostty="config-file = \"$DOTFILES_ROOT/config/ghostty/common.conf\""$'\n'"config-file = \"$DOTFILES_ROOT/config/ghostty/$DOTFILES_PLATFORM.conf\""
add_file "$HOME/.config/ghostty/config" "$ghostty"
printf -v env_content 'export DOTFILES_ROOT=%q\nexport DOTFILES_PROFILE=%q\n. "$DOTFILES_ROOT/shell/init.sh"' "$DOTFILES_ROOT" "$profile"
add_file "$HOME/.config/dotfiles/env.sh" "$env_content"
startup='[ ! -r "$HOME/.config/dotfiles/env.sh" ] || . "$HOME/.config/dotfiles/env.sh"'
case "$DOTFILES_PLATFORM" in omarchy) rc=.bashrc ;; macos) rc=.zshrc ;; esac
path="$HOME/$rc"
[ ! -L "$path" ] || { echo "Startup file is a symlink: $path. Review before migration." >&2; exit 1; }
previous=''
if [ -f "$path" ]; then previous=$(cat "$path"); fi
if printf '%s' "$previous" | grep -Eq '(shell-scripts/init\.sh|dotagents/install\.sh)'; then
  [ "$migrate_shell" = 1 ] || {
    echo "Legacy loader in $path; use --migrate-shell --backup to replace a standalone source line." >&2
    exit 1
  }
  migrated=''
  while IFS= read -r line; do
    case "$line" in
      'source ~/shell-scripts/init.sh'|'. ~/shell-scripts/init.sh'|\
      'source "$HOME/shell-scripts/init.sh"'|'. "$HOME/shell-scripts/init.sh"') continue ;;
    esac
    migrated+="$line"$'\n'
  done <<< "$previous"
  previous=${migrated%$'\n'}
  if printf '%s' "$previous" | grep -Eq '(shell-scripts/init\.sh|dotagents/install\.sh)'; then
    echo "Unrecognized legacy loader in $path; review manually. No files changed." >&2
    exit 1
  fi
fi
if ! printf '%s\n' "$previous" | grep -Fqx "$startup"; then
  previous="${previous}${previous:+$'\n'}$startup"
fi
add_file "$path" "$previous"

if [ "$DOTFILES_AGENTS" = 1 ]; then
  for entry in '.claude/CLAUDE.md' '.codex/AGENTS.md' '.gemini/config/AGENTS.md' '.config/opencode/AGENTS.md' '.agents/AGENTS.md'; do
    add_link "$DOTFILES_ROOT/agents/AGENTS.md" "$HOME/$entry"
  done
  for base in .claude/skills .codex/skills .gemini/config/skills .agents/skills; do
    # Never follow an old whole-directory symlink into another repository.
    [ ! -L "$HOME/$base" ] || { echo "Whole skills directory is a symlink: $HOME/$base. Migrate it first." >&2; exit 1; }
    for skill in "$DOTFILES_ROOT"/agents/skills/*; do
      [ -f "$skill/SKILL.md" ] || continue
      add_link "$skill" "$HOME/$base/${skill##*/}"
    done
  done
fi
conflicts=0
for ((i=0; i<${#targets[@]}; i++)); do
  target=${targets[i]}; source=${sources[i]}
  if [ -n "$source" ] && [ "$(readlink "$target" 2>/dev/null || true)" = "$source" ]; then continue; fi
  if [ -z "$source" ] && [ -f "$target" ] && [ ! -L "$target" ] && [ "$(cat "$target")" = "${contents[i]}" ]; then continue; fi
  printf '%s %s\n' "$([ -n "$source" ] && echo LINK || echo WRITE)" "$target"
  if [ -e "$target" ] || [ -L "$target" ]; then
    printf '  Existing destination requires --backup: %s\n' "$target"
    conflicts=1
  fi
done
if [ "$packages" = 1 ]; then "$DOTFILES_ROOT/scripts/packages.sh" "$profile"; fi
[ "$apply" = 1 ] || { echo 'Preview complete. Use --apply to install configs; --backup to preserve conflicts.'; exit 0; }
[ "$conflicts" = 0 ] || [ "$backup" = 1 ] || { echo 'No files changed. Resolve conflicts or use --backup.' >&2; exit 1; }
for ((i=0; i<${#targets[@]}; i++)); do
  target=${targets[i]}; source=${sources[i]}
  if [ -n "$source" ] && [ "$(readlink "$target" 2>/dev/null || true)" = "$source" ]; then continue; fi
  if [ -z "$source" ] && [ -f "$target" ] && [ ! -L "$target" ] && [ "$(cat "$target")" = "${contents[i]}" ]; then continue; fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    saved="$backup_root/${target#"$HOME/"}"
    mkdir -p "$(dirname "$saved")"
    mv "$target" "$saved"
  fi
  mkdir -p "$(dirname "$target")"
  if [ -n "$source" ]; then ln -s "$source" "$target"; else printf '%s\n' "${contents[i]}" > "$target"; fi
done
if [ "$packages" = 1 ]; then "$DOTFILES_ROOT/scripts/packages.sh" "$profile" --apply; fi
printf 'Configuration applied for %s. Backups, if needed: %s\n' "$profile" "$backup_root"
