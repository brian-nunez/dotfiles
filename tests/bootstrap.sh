#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
sandbox=$(mktemp -d)
trap 'rm -rf "$sandbox"' EXIT
mkdir -p "$sandbox/bin"
cat > "$sandbox/bin/uname" <<'MOCK'
#!/usr/bin/env bash
case "$1" in -s) echo "${TEST_OS:-Linux}" ;; -m) echo "${TEST_ARCH:-x86_64}" ;; esac
MOCK
for tool in brew sudo; do
  cat > "$sandbox/bin/$tool" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$PACKAGE_LOG"
MOCK
  chmod +x "$sandbox/bin/$tool"
done
chmod +x "$sandbox/bin/uname"
export PATH="$sandbox/bin:$PATH"
export PACKAGE_LOG="$sandbox/packages"
for profile in omarchy mac-personal mac-work; do
  export HOME="$sandbox/$profile"
  mkdir -p "$HOME/.local/share/omarchy" "$HOME/.codex/skills/external"
  echo keep > "$HOME/.codex/skills/external/marker"
  if [ "$profile" = omarchy ]; then export TEST_OS=Linux TEST_ARCH=x86_64; else export TEST_OS=Darwin TEST_ARCH=arm64; fi
  "$root/bootstrap.sh" "$profile" --packages > "$sandbox/preview"
  [ ! -e "$HOME/.bashrc" ]
  [ ! -e "$PACKAGE_LOG" ]
  if [ "$profile" = mac-work ]; then ! grep -q tailscale "$sandbox/preview"; else grep -q tailscale "$sandbox/preview"; fi
  "$root/bootstrap.sh" "$profile" --apply > /dev/null
  [ -L "$HOME/.config/tmux/tmux.conf" ]
  [ -f "$HOME/.codex/skills/external/marker" ]
  "$root/bootstrap.sh" "$profile" --apply > "$sandbox/repeat"
  ! grep -Eq '^(LINK|WRITE)' "$sandbox/repeat"
  if [ "$profile" = omarchy ]; then
    startup_rc=.bashrc; other_rc=.zshrc
  else
    startup_rc=.zshrc; other_rc=.bashrc
  fi
  [ "$(grep -c 'env.sh' "$HOME/$startup_rc")" = 1 ]
  [ ! -e "$HOME/$other_rc" ]
  bash -c '. "$HOME/.config/dotfiles/env.sh"; . "$HOME/.config/dotfiles/env.sh"' > /dev/null
  # Conflicts stop before any other planned mutation.
  mv "$HOME/.config/tmux/tmux.conf" "$HOME/.config/tmux/original-link"
  echo original > "$HOME/.config/tmux/tmux.conf"
  rm "$HOME/.config/ghostty/config"
  if "$root/bootstrap.sh" "$profile" --apply > /dev/null 2>&1; then exit 1; fi
  [ ! -e "$HOME/.config/ghostty/config" ]
  "$root/bootstrap.sh" "$profile" --apply --backup > /dev/null
  saved=$(find "$HOME/.local/state/dotfiles/backups" -type f -name tmux.conf)
  [ "$(cat "$saved")" = original ]
  export TEST_OS=Other
  if "$root/bootstrap.sh" "$profile" --apply > /dev/null 2>&1; then exit 1; fi
done
export TEST_OS=Darwin TEST_ARCH=arm64
export HOME="$sandbox/legacy"
mkdir -p "$HOME"
echo 'source "$HOME/shell-scripts/init.sh"' > "$HOME/.zshrc"
if "$root/bootstrap.sh" mac-work --apply --backup > /dev/null 2>&1; then exit 1; fi
[ ! -e "$HOME/.config/tmux/tmux.conf" ]
"$root/bootstrap.sh" mac-work --apply --backup --migrate-shell > /dev/null
! grep -q shell-scripts "$HOME/.zshrc"
[ "$(grep -c env.sh "$HOME/.zshrc")" = 1 ]
legacy_backup=$(find "$HOME/.local/state/dotfiles/backups" -type f -name .zshrc)
grep -Fq 'source "$HOME/shell-scripts/init.sh"' "$legacy_backup"
"$root/bootstrap.sh" mac-work --apply --migrate-shell > /dev/null
export HOME="$sandbox/packages-home"
mkdir -p "$HOME"
"$root/scripts/packages.sh" mac-work --apply > /dev/null
! grep -q tailscale "$PACKAGE_LOG"
grep -q ghostty "$PACKAGE_LOG"
# Invalid flags fail before any write; use a temporary copy for local overrides.
cp -R "$root" "$sandbox/repo"
mkdir -p "$sandbox/repo/local"
echo DOTFILES_DOCKER=invalid > "$sandbox/repo/local/mac-work.sh"
if "$sandbox/repo/bootstrap.sh" mac-work --apply > /dev/null 2>&1; then exit 1; fi
[ ! -e "$HOME/.config/tmux/tmux.conf" ]
echo DOTFILES_AGENTS=0 > "$sandbox/repo/local/mac-work.sh"
echo DOTFILES_DOCKER=0 >> "$sandbox/repo/local/mac-work.sh"
"$sandbox/repo/bootstrap.sh" mac-work --apply > /dev/null
[ ! -e "$HOME/.codex/AGENTS.md" ]
"$sandbox/repo/bootstrap.sh" mac-work --packages > "$sandbox/disabled"
! grep -q docker-compose "$sandbox/disabled"
echo 'All bootstrap tests passed.'
