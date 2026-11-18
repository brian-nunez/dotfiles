#!/usr/bin/env bash
#
# Link this repository's configuration into $HOME for one machine profile.
# Previews by default; --apply writes. Bash 3.2 compatible for macOS.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install.sh <profile> [--apply] [--packages]

Profiles: omarchy, mac-personal, mac-work

  --apply     Make the changes. Without it, only print what would change.
  --packages  Also install packages (pacman on Omarchy, Homebrew on macOS).

Existing files are backed up to ~/.local/state/dotfiles/backups/ before
they are replaced.
EOF
}

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

profile=""
apply=0
packages=0
pending=0
backup_dir=""

for arg in "$@"; do
  case "$arg" in
    --apply) apply=1 ;;
    --packages) packages=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      usage >&2
      exit 2
      ;;
    *) profile=$arg ;;
  esac
done

if [ -z "$profile" ] || [ ! -f "$DOTFILES_ROOT/profiles/$profile.sh" ]; then
  usage >&2
  exit 2
fi

# shellcheck source=profiles/common.sh
. "$DOTFILES_ROOT/profiles/common.sh"
# shellcheck disable=SC1090
. "$DOTFILES_ROOT/profiles/$profile.sh"
if [ -f "$DOTFILES_ROOT/local/$profile.sh" ]; then
  # shellcheck disable=SC1090
  . "$DOTFILES_ROOT/local/$profile.sh"
fi

say() {
  printf '%s\n' "$*"
}

# Records a pending change and reports whether it should be made now.
change() {
  pending=$((pending + 1))
  if [ "$apply" = 1 ]; then
    say "  apply: $*"
    return 0
  fi
  say "  would: $*"
  return 1
}

# Expands a leading literal $HOME, as written in profile values.
expand_home() {
  case "$1" in
    '$HOME'*) printf '%s%s\n' "$HOME" "${1#\$HOME}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

# Prints a path relative to $HOME as $HOME/..., for portable startup files.
home_relative() {
  case "$1" in
    "$HOME"/*) printf '$HOME/%s\n' "${1#"$HOME"/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

backup() {
  local target=$1
  local relative

  [ -e "$target" ] || [ -L "$target" ] || return 0

  if [ -z "$backup_dir" ]; then
    backup_dir="$HOME/.local/state/dotfiles/backups/$(date +%Y%m%dT%H%M%S)-$$"
  fi

  relative=${target#"$HOME"/}
  mkdir -p "$backup_dir/$(dirname "$relative")"
  cp -RPp "$target" "$backup_dir/$relative"
  say "    backed up to $backup_dir/$relative"
}

link() {
  local source=$1
  local target=$2

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    say "  ok:    $target"
    return 0
  fi

  change "link $target -> $source" || return 0

  backup "$target"
  rm -rf "$target"
  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
}

check_host() {
  local kernel=${DOTFILES_UNAME:-$(uname -s)}

  case "$DOTFILES_PLATFORM:$kernel" in
    omarchy:Linux | macos:Darwin) ;;
    *)
      say "Profile '$profile' is for $DOTFILES_PLATFORM, but this host is $kernel." >&2
      exit 1
      ;;
  esac
}

# The block sourced from the shell startup file. Paths stay $HOME-relative.
loader_block() {
  local init

  init=$(home_relative "$DOTFILES_ROOT/shell-scripts/init.sh")
  printf '%s\n' \
    '# >>> dotfiles >>>' \
    "export WORKSPACE_DIR=\"$DOTFILES_WORKSPACE\"" \
    "source \"$init\"" \
    '# <<< dotfiles <<<'
}

# Rewrites a startup file: drops any previous dotfiles block and legacy
# "source .../shell-scripts/init.sh" lines, then puts the block where the
# first of them was, or at the end of the file.
render_startup_file() {
  local file=$1
  local block=$2

  DOTFILES_BLOCK=$block awk '
    BEGIN { block = ENVIRON["DOTFILES_BLOCK"]; placed = 0; inside = 0 }
    /^# >>> dotfiles >>>$/ { inside = 1; if (!placed) { print block; placed = 1 }; next }
    /^# <<< dotfiles <<<$/ { inside = 0; next }
    inside { next }
    /^[[:space:]]*(source|\.)[[:space:]]+["]?[^ ]*shell-scripts\/init\.sh["]?[[:space:]]*$/ {
      if (!placed) { print block; placed = 1 }
      next
    }
    { print }
    END { if (!placed) print block }
  ' "$file"
}

install_shell() {
  local rc="$HOME/$DOTFILES_SHELL_RC"
  local block rendered

  block=$(loader_block)
  if [ -f "$rc" ]; then
    rendered=$(render_startup_file "$rc" "$block")
  else
    rendered=$block
  fi

  if [ -f "$rc" ] && [ "$rendered" = "$(cat "$rc")" ]; then
    say "  ok:    $rc"
    return 0
  fi

  change "load shell-scripts/init.sh from $rc" || return 0

  backup "$rc"
  printf '%s\n' "$rendered" >"$rc"
}

install_tmux() {
  link "$DOTFILES_ROOT/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
}

install_ghostty() {
  local legacy="$HOME/Library/Application Support/com.mitchellh.ghostty/config"

  link "$DOTFILES_ROOT/ghostty/$DOTFILES_PLATFORM/config" "$HOME/.config/ghostty/config"

  if [ "$DOTFILES_PLATFORM" = macos ]; then
    link "$DOTFILES_ROOT/ghostty/macos/themes/Monokai SublimeText" \
      "$HOME/.config/ghostty/themes/Monokai SublimeText"

    if [ -f "$legacy" ]; then
      say "  note:  $legacy also loads, after ~/.config/ghostty/config."
      say "         Move it aside so it does not override these settings."
    fi
  fi
}

# True when every instruction file and skill already links into this repo.
agents_linked() {
  local src="$DOTFILES_ROOT/dotagents/src"
  local skill name root

  for name in .gemini/config/AGENTS.md .codex/AGENTS.md .claude/CLAUDE.md \
    .config/opencode/AGENTS.md .agents/AGENTS.md; do
    [ "$(readlink "$HOME/$name" 2>/dev/null || true)" = "$src/AGENTS.md" ] || return 1
  done

  for skill in "$src"/skills/*/; do
    skill=${skill%/}
    [ -f "$skill/SKILL.md" ] || continue
    name=${skill##*/}
    for root in .gemini/config/skills .codex/skills .claude/skills .agents/skills; do
      [ "$(readlink "$HOME/$root/$name" 2>/dev/null || true)" = "$skill" ] || return 1
    done
  done
}

install_agents() {
  local source="$DOTFILES_ROOT/dotagents/src/AGENTS.md"
  local target

  if [ "$DOTFILES_AGENTS" != 1 ]; then
    say "  skip:  agents (DOTFILES_AGENTS=0)"
    return 0
  fi

  if agents_linked; then
    say "  ok:    agent instructions and skills"
    return 0
  fi

  change "run dotagents/install.sh" || return 0

  # dotagents/install.sh replaces these with symlinks; keep any real files.
  for target in \
    "$HOME/.gemini/config/AGENTS.md" \
    "$HOME/.codex/AGENTS.md" \
    "$HOME/.claude/CLAUDE.md" \
    "$HOME/.config/opencode/AGENTS.md" \
    "$HOME/.agents/AGENTS.md"; do
    if [ -f "$target" ] && [ ! -L "$target" ]; then
      backup "$target"
    fi
  done

  bash "$DOTFILES_ROOT/dotagents/install.sh" >/dev/null
}

install_packages() {
  local formulae casks pacman_packages appdir

  if [ "$DOTFILES_PLATFORM" = omarchy ]; then
    pacman_packages=(git neovim tmux fzf go nodejs npm ghostty ttf-jetbrains-mono-nerd)
    [ "$DOTFILES_JAVA" = 1 ] && pacman_packages+=(jdk21-openjdk)
    [ "$DOTFILES_RUBY" = 1 ] && pacman_packages+=(rbenv ruby-build)
    [ "$DOTFILES_ARDUINO" = 1 ] && pacman_packages+=(arduino-cli)
    [ "$DOTFILES_DOCKER" = 1 ] && pacman_packages+=(docker docker-compose)
    [ "$DOTFILES_TAILSCALE" = 1 ] && pacman_packages+=(tailscale)

    change "sudo pacman -S --needed ${pacman_packages[*]}" || return 0
    sudo pacman -S --needed "${pacman_packages[@]}"
    return 0
  fi

  formulae=(git neovim tmux fzf go node)
  casks=(ghostty font-jetbrains-mono-nerd-font)
  [ "$DOTFILES_JAVA" = 1 ] && formulae+=(openjdk@21)
  [ "$DOTFILES_RUBY" = 1 ] && formulae+=(rbenv ruby-build)
  [ "$DOTFILES_ARDUINO" = 1 ] && formulae+=(arduino-cli)
  [ "$DOTFILES_DOCKER" = 1 ] && formulae+=(docker docker-compose)
  [ "$DOTFILES_TAILSCALE" = 1 ] && casks+=(tailscale-app)

  appdir=""
  if [ -n "${DOTFILES_BREW_APPDIR:-}" ]; then
    appdir="--appdir=$(expand_home "$DOTFILES_BREW_APPDIR")"
  fi

  if ! command -v brew >/dev/null 2>&1 && [ -x /opt/homebrew/bin/brew ]; then
    PATH="/opt/homebrew/bin:$PATH"
  fi

  change "brew install ${formulae[*]}" &&
    brew install "${formulae[@]}"
  change "brew install --cask ${appdir:+$appdir }${casks[*]}" &&
    brew install --cask ${appdir:+"$appdir"} "${casks[@]}"
  return 0
}

main() {
  check_host

  if [ "$apply" = 1 ]; then
    say "Applying profile '$profile'"
  else
    say "Previewing profile '$profile' (nothing is changed; add --apply)"
  fi

  if [ "$packages" = 1 ]; then
    say "Packages"
    install_packages
  fi

  say "Shell"
  install_shell
  say "tmux"
  install_tmux
  say "Ghostty"
  install_ghostty
  say "Agents"
  install_agents

  if [ "$pending" = 0 ]; then
    say "Up to date."
  elif [ "$apply" = 0 ]; then
    say "$pending change(s) pending."
  else
    say "Done. Open a new terminal to load the shell changes."
  fi
}

main
