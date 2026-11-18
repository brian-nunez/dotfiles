# Sourced by bootstrap and the interactive shell. Compatible with Bash 3.2 and Zsh.
dotfiles_load_profile() {
  case "$1" in omarchy|mac-personal|mac-work) ;; *) printf 'Unknown profile: %s\n' "$1" >&2; return 1 ;; esac
  DOTFILES_PROFILE=$1
  . "$DOTFILES_ROOT/profiles/common.sh"
  . "$DOTFILES_ROOT/profiles/$DOTFILES_PROFILE.sh"
  if [ -f "$DOTFILES_ROOT/local/$DOTFILES_PROFILE.sh" ]; then
    . "$DOTFILES_ROOT/local/$DOTFILES_PROFILE.sh"
  fi
  for dotfiles_flag in AGENTS DOCKER JAVA RUBY ARDUINO TAILSCALE ARTCRAFT GHIDRA; do
    eval 'dotfiles_value=${DOTFILES_'"$dotfiles_flag"'}'
    case "$dotfiles_value" in 0|1) ;; *) printf 'DOTFILES_%s must be 0 or 1\n' "$dotfiles_flag" >&2; return 1 ;; esac
  done
  unset dotfiles_flag dotfiles_value
}
