#!/usr/bin/env bash
#
# Runs install.sh against throwaway home directories.

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Fake pacman: "-T" reports every package as missing except those listed in
# FAKE_PACMAN_INSTALLED, so package tests do not depend on the host.
mkdir -p "$WORK/bin"
cat >"$WORK/bin/pacman" <<'EOF_PACMAN'
#!/usr/bin/env bash
[ "$1" = -T ] || exit 1
shift
missing=0
for package in "$@"; do
  case " ${FAKE_PACMAN_INSTALLED:-} " in
    *" $package "*) ;;
    *)
      echo "$package"
      missing=1
      ;;
  esac
done
[ "$missing" = 0 ] || exit 127
EOF_PACMAN
chmod +x "$WORK/bin/pacman"
export PATH="$WORK/bin:$PATH"

failures=0
start_failures=0
current=""

# Each test gets a fresh, empty home directory.
start() {
  current=$1
  start_failures=$failures
  export HOME="$WORK/$current"
  mkdir -p "$HOME"
  unset DOTFILES_UNAME
}

fail() {
  printf 'FAIL %s: %s\n' "$current" "$*"
  failures=$((failures + 1))
}

pass() {
  [ "$failures" = "$start_failures" ] && printf 'ok   %s\n' "$current"
  return 0
}

run() {
  "$ROOT/install.sh" "$@" >"$HOME.log" 2>&1
}

expect_link() {
  [ "$(readlink "$1" 2>/dev/null || true)" = "$2" ] || fail "$1 does not link to $2"
}

expect_log() {
  grep -qF -- "$1" "$HOME.log" || fail "output lacks: $1"
}

reject_log() {
  ! grep -qF -- "$1" "$HOME.log" || fail "output contains: $1"
}

count_lines() {
  grep -cF -- "$1" "$2" || true
}

start preview-writes-nothing
run omarchy
[ -z "$(ls -A "$HOME")" ] || fail "preview created files"
expect_log "would: link $HOME/.config/tmux/tmux.conf"
pass

start omarchy-apply
run omarchy --apply || fail "apply failed"
expect_link "$HOME/.config/tmux/tmux.conf" "$ROOT/tmux/tmux.conf"
expect_link "$HOME/.config/ghostty/config" "$ROOT/ghostty/omarchy/config"
expect_link "$HOME/.config/ghostty/themes/Monokai SublimeText" "$ROOT/ghostty/themes/Monokai SublimeText"
expect_link "$HOME/.claude/CLAUDE.md" "$ROOT/dotagents/src/AGENTS.md"
expect_link "$HOME/.claude/skills/operate" "$ROOT/dotagents/src/skills/operate"
grep -qF 'export WORKSPACE_DIR="$HOME/workspace"' "$HOME/.bashrc" || fail "WORKSPACE_DIR missing"
grep -qF "source \"$ROOT/shell-scripts/init.sh\"" "$HOME/.bashrc" || fail "loader missing"
[ ! -e "$HOME/.zshrc" ] || fail "omarchy wrote .zshrc"
run omarchy --apply
expect_log "Up to date."
[ "$(count_lines '# >>> dotfiles >>>' "$HOME/.bashrc")" = 1 ] || fail "loader duplicated"
pass

start legacy-loader-replaced
printf '%s\n' '# before' 'source ~/shell-scripts/init.sh' '# after' >"$HOME/.bashrc"
mkdir -p "$HOME/.config/tmux"
printf 'set -g mouse on\n' >"$HOME/.config/tmux/tmux.conf"
run omarchy --apply
[ "$(count_lines 'shell-scripts/init.sh' "$HOME/.bashrc")" = 1 ] || fail "legacy loader kept"
[ "$(sed -n 1p "$HOME/.bashrc")" = '# before' ] || fail "content before loader changed"
[ "$(sed -n 2p "$HOME/.bashrc")" = '# >>> dotfiles >>>' ] || fail "block not in legacy position"
[ "$(tail -n 1 "$HOME/.bashrc")" = '# after' ] || fail "content after loader changed"
backups=$(find "$HOME/.local/state/dotfiles/backups" -type f | sort)
printf '%s\n' "$backups" | grep -q '/\.bashrc$' || fail ".bashrc not backed up"
printf '%s\n' "$backups" | grep -q '/\.config/tmux/tmux\.conf$' || fail "tmux.conf not backed up"
pass

start shell-loads-in-bash
run omarchy --apply
out=$(bash -c '. "$HOME/.bashrc"; type goto >/dev/null && type gotogit >/dev/null && echo "ws=$WORKSPACE_DIR"' 2>&1) ||
  fail "sourcing .bashrc failed: $out"
printf '%s\n' "$out" | grep -qF 'Initialized Shell Config (bash)' || fail "shell.bash.sh not loaded"
printf '%s\n' "$out" | grep -qF "ws=$HOME/workspace" || fail "WORKSPACE_DIR not exported"
pass

start shell-loads-in-zsh
if command -v zsh >/dev/null 2>&1; then
  export DOTFILES_UNAME=Darwin
  run mac-personal --apply
  out=$(zsh -c '. "$HOME/.zshrc"; whence goto >/dev/null && echo "ws=$WORKSPACE_DIR"' 2>&1) ||
    fail "sourcing .zshrc failed: $out"
  printf '%s\n' "$out" | grep -qF 'Initialized Shell Config (zsh)' || fail "shell.zsh.sh not loaded"
  printf '%s\n' "$out" | grep -qF "ws=$HOME/Documents/workspace" || fail "WORKSPACE_DIR not exported"
  pass
else
  printf 'skip %s: zsh not installed\n' "$current"
fi

start mac-personal-apply
export DOTFILES_UNAME=Darwin
run mac-personal --apply || fail "apply failed"
expect_link "$HOME/.config/ghostty/config" "$ROOT/ghostty/macos/config"
expect_link "$HOME/.config/ghostty/themes/Monokai SublimeText" "$ROOT/ghostty/themes/Monokai SublimeText"
grep -qF 'export WORKSPACE_DIR="$HOME/Documents/workspace"' "$HOME/.zshrc" || fail "WORKSPACE_DIR missing"
[ ! -e "$HOME/.bashrc" ] || fail "mac wrote .bashrc"
pass

start omarchy-skips-installed-packages
export FAKE_PACMAN_INSTALLED="git ttf-jetbrains-mono-nerd"
run omarchy --packages
expect_log "would: sudo pacman -S --needed neovim"
reject_log "ttf-jetbrains-mono-nerd"
reject_log " git "
export FAKE_PACMAN_INSTALLED="git neovim tmux fzf go nodejs npm ghostty ttf-jetbrains-mono-nerd docker docker-compose tailscale"
run omarchy --packages
expect_log "ok:    packages"
reject_log "pacman -S"
unset FAKE_PACMAN_INSTALLED
pass

start packages-per-profile
run omarchy --packages
reject_log "jdk21-openjdk"
reject_log "rbenv"
reject_log "arduino-cli"
expect_log "tailscale"
export DOTFILES_UNAME=Darwin
run mac-personal --packages
expect_log "arduino-cli"
expect_log "tailscale-app"
reject_log "openjdk@21"
reject_log "rbenv"
reject_log "--appdir"
run mac-work --packages
expect_log "openjdk@21"
expect_log "--appdir=$HOME/Applications"
reject_log "arduino-cli"
reject_log "tailscale-app"
reject_log "rbenv"
pass

start local-override
mkdir -p "$ROOT/local"
override="$ROOT/local/omarchy.sh"
[ ! -e "$override" ] || fail "refusing to replace existing $override"
if [ ! -e "$override" ]; then
  printf 'DOTFILES_DOCKER=0\nDOTFILES_AGENTS=0\n' >"$override"
  run omarchy --packages
  rm -f "$override"
  rmdir "$ROOT/local" 2>/dev/null || true
  reject_log "docker"
  expect_log "skip:  agents"
fi
pass

start host-mismatch
export DOTFILES_UNAME=Darwin
if run omarchy; then
  fail "omarchy profile ran on Darwin"
fi
expect_log "but this host is Darwin"
pass

if [ "$failures" -gt 0 ]; then
  printf '%d failure(s)\n' "$failures"
  exit 1
fi
printf 'All tests passed.\n'
