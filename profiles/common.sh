# Shared defaults. Profiles override these; local/<profile>.sh overrides both.
# Feature flags control which optional packages --packages installs.
DOTFILES_AGENTS=1
DOTFILES_DOCKER=1
DOTFILES_JAVA=0
DOTFILES_RUBY=0
DOTFILES_ARDUINO=0
DOTFILES_TAILSCALE=1

# Written literally into the shell startup file as WORKSPACE_DIR.
DOTFILES_WORKSPACE='$HOME/Documents/workspace'
