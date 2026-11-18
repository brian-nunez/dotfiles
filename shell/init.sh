# Load through ~/.config/dotfiles/env.sh; do not source secrets during installation.
[ -n "${DOTFILES_ROOT:-}" ] || return 1
. "$DOTFILES_ROOT/scripts/profile.sh"
dotfiles_load_profile "$DOTFILES_PROFILE" || return 1
SHELL_SCRIPTS_DIR="$DOTFILES_ROOT/shell"
_shell_scripts_prepend_path() {
  [ -n "$1" ] || return 0
  case ":$PATH:" in *":$1:"*) ;; *) PATH="$1${PATH:+:$PATH}" ;; esac
  export PATH
}
for dotfiles_module in homebrew shell javascript go functions search git alias; do
  . "$SHELL_SCRIPTS_DIR/$dotfiles_module.sh"
done
for dotfiles_pair in AGENTS:ai DOCKER:docker JAVA:java RUBY:ruby ARDUINO:arduino ARTCRAFT:artcraft GHIDRA:ghidra; do
  dotfiles_flag=${dotfiles_pair%%:*}
  eval 'dotfiles_enabled=${DOTFILES_'"$dotfiles_flag"'}'
  if [ "$dotfiles_enabled" = 1 ]; then
    . "$SHELL_SCRIPTS_DIR/${dotfiles_pair#*:}.sh"
  fi
done
# Private file stays outside the public repository and is read only by the user's shell.
if [ -f "$HOME/.config/dotfiles/secrets.sh" ]; then
  . "$HOME/.config/dotfiles/secrets.sh"
elif [ -f "$HOME/shell-scripts/secrets.sh" ]; then
  # Preserve the existing private file in place during migration.
  . "$HOME/shell-scripts/secrets.sh"
fi
unset dotfiles_module dotfiles_pair dotfiles_flag dotfiles_enabled SHELL_SCRIPTS_DIR
unset -f _shell_scripts_prepend_path
