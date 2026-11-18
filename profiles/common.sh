# Shared defaults. Profiles override these; local/<profile>.sh overrides both.
# Feature flags control which optional packages --packages installs.
DOTFILES_AGENTS=1
DOTFILES_DOCKER=1
DOTFILES_JAVA=1
DOTFILES_RUBY=1
DOTFILES_ARDUINO=1
DOTFILES_TAILSCALE=1

# Written literally into the shell startup file as WORKSPACE_DIR.
DOTFILES_WORKSPACE='$HOME/Documents/workspace'
