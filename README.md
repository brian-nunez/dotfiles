# dotfiles

Brian's machine setup for Omarchy and Apple Silicon Macs (personal and work):
shell scripts, agent instructions and skills, tmux, and Ghostty.

## Layout

| Path | Contents |
| --- | --- |
| `shell-scripts/` | Shell environment, imported from [shell-scripts](https://github.com/brian-nunez/shell-scripts). Load it with `source /path/to/shell-scripts/init.sh`. |
| `dotagents/` | Agent instructions and skills, imported from [dotagents](https://github.com/brian-nunez/dotagents), with its own `install.sh`. |
| `tmux/tmux.conf` | tmux configuration. |
| `ghostty/omarchy/config` | Ghostty on Omarchy (follows the Omarchy theme). |
| `ghostty/macos/` | Ghostty on macOS: Brian's Mac settings, portable Omarchy settings, and the Monokai SublimeText theme. |
| `profiles/` | Per-machine settings: shell startup file, workspace directory, optional packages. |
| `install.sh` | Links everything into `$HOME` for one profile. |

## Install

On macOS, install Homebrew and the Xcode Command Line Tools first. A work Mac
without admin access needs Homebrew provisioned by IT.

```bash
git clone https://github.com/brian-nunez/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
./install.sh omarchy                       # preview
./install.sh omarchy --apply --packages    # apply and install packages
```

Profiles: `omarchy`, `mac-personal`, `mac-work`. The installer:

- Adds this block to `~/.bashrc` (Omarchy) or `~/.zshrc` (macOS), replacing
  any older `source .../shell-scripts/init.sh` line:

  ```bash
  # >>> dotfiles >>>
  export WORKSPACE_DIR="$HOME/workspace"
  source "$HOME/workspace/dotfiles/shell-scripts/init.sh"
  # <<< dotfiles <<<
  ```

- Links `~/.config/tmux/tmux.conf` and `~/.config/ghostty/config` (plus the
  theme on macOS).
- Runs `dotagents/install.sh` to link agent instructions and skills.
- With `--packages`, installs packages with pacman (Omarchy) or Homebrew
  (macOS). The work profile skips Tailscale and installs apps into
  `~/Applications`.

Files that get replaced are backed up first, under
`~/.local/state/dotfiles/backups/<timestamp>/`. Run the installer again any time; it
only changes what differs.

## Per-machine settings

| Setting | Omarchy | mac-personal | mac-work |
| --- | --- | --- | --- |
| Shell startup file | `~/.bashrc` | `~/.zshrc` | `~/.zshrc` |
| `WORKSPACE_DIR` (used by `goto`, `gtg`) | `~/workspace` | `~/Documents/workspace` | `~/Documents/workspace` |
| Tailscale | yes | yes | no |

To change a setting on one machine only, create `local/<profile>.sh`. This
directory is ignored by git:

```bash
DOTFILES_DOCKER=0
DOTFILES_WORKSPACE='$HOME/code'
```

Package flags: `DOTFILES_AGENTS`, `DOTFILES_DOCKER`, `DOTFILES_JAVA`,
`DOTFILES_RUBY`, `DOTFILES_ARDUINO`, `DOTFILES_TAILSCALE`.

## Secrets

`shell-scripts/init.sh` loads `shell-scripts/secrets.sh` last if it exists.
That file is ignored by git. Create it (or symlink it) on each machine; never
commit it.

## Notes

- Ghostty on macOS: `window-decoration = none` hides the native tabs. If
  `~/Library/Application Support/com.mitchellh.ghostty/config` exists, it loads
  after `~/.config/ghostty/config` and overrides it. The installer warns when
  that file exists.
- The tmux `?` binding runs `omarchy-menu-tmux-keybindings`, which exists only
  on Omarchy.

## Development

Format the setup scripts with [shfmt](https://github.com/mvdan/sh). Settings
come from `.editorconfig`. Imported files in `shell-scripts/` and `dotagents/`
keep their original formatting.

```bash
shfmt -w install.sh profiles tests
bash tests/install.sh
```

The tests run the installer against temporary home directories.

Inspired by [thdxr/environment](https://github.com/thdxr/environment) and
[madflojo/dotfiles](https://github.com/madflojo/dotfiles).
