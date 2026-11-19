<p align="center">
  <img src="docs/brand/icon.svg" width="128" height="128" alt="dotfiles icon: an engraved hermit crab beneath a spiral shell on a deep teal tile">
</p>

<h1 align="center">dotfiles</h1>

<p align="center">
  <b>Machine setup; one installer that links shell, agent, tmux and Ghostty configuration into $HOME.</b>
</p>

<p align="center">
  Brian's environment for Omarchy and Apple Silicon Macs, personal and work, with a profile per machine and a preview before anything changes.<br>
  <i>By Brian Nunez.</i>
</p>

<p align="center">
  <img alt="Runs on Omarchy and macOS" src="https://img.shields.io/badge/runs%20on-Omarchy%20%C2%B7%20macOS-0f6b6b?style=flat-square">
  <br>
  <a href="https://www.linkedin.com/in/brianjnunez/"><img alt="LinkedIn: Brian Nunez" src="https://img.shields.io/badge/LinkedIn-Brian%20Nunez-0A66C2?style=flat-square&logo=linkedin&logoColor=white"></a>
</p>

<p align="center">
  <a href="#quick-start"><img alt="Install" src="https://img.shields.io/badge/Install-0f6b6b?style=for-the-badge&logo=gnubash&logoColor=white" height="40"></a>
</p>

<p align="center">
  <a href="#quick-start"><b>Quick start</b></a> ·
  <a href="#profiles">Profiles</a> ·
  <a href="shell-scripts/README.md">Shell scripts</a> ·
  <a href="dotagents/README.md">dotagents</a>
</p>

<br>

> [!NOTE]
> **The installer only previews by default.** `./install.sh <profile>` prints what it would change; nothing is written until you add `--apply`.

<p align="center">
  <a href="#why-dotfiles">Why dotfiles</a> ·
  <a href="#whats-included">What's included</a> ·
  <a href="#quick-start">Quick start</a> ·
  <a href="#what-the-installer-does">What the installer does</a> ·
  <a href="#profiles">Profiles</a> ·
  <a href="#secrets">Secrets</a> ·
  <a href="#development">Development</a>
</p>

## Why dotfiles

- **Safe.** Every run is a dry run unless you pass `--apply`, and any file that gets replaced is first backed up under `~/.local/state/dotfiles/backups/<timestamp>/`.
- **Repeatable.** Run the installer again any time; it reports `ok` for what already matches and only changes what differs.
- **Live.** Configuration is symlinked, not copied, so an edit in this repository takes effect on the next shell, tmux reload or Ghostty launch.
- **Per machine.** One profile per machine type sets the shell startup file, workspace directory and optional packages, and a git-ignored `local/<profile>.sh` overrides any of it on a single machine.

## What's included

| Path | Contents |
| --- | --- |
| [`shell-scripts/`](shell-scripts/README.md) | Shell environment for Bash and Zsh, imported from [shell-scripts](https://github.com/brian-nunez/shell-scripts). Loaded through `shell-scripts/init.sh`. |
| [`dotagents/`](dotagents/README.md) | Agent instructions and skills, imported from [dotagents](https://github.com/brian-nunez/dotagents), with its own `install.sh`. |
| [`tmux/tmux.conf`](tmux/tmux.conf) | tmux configuration. |
| [`ghostty/omarchy/config`](ghostty/omarchy/config) | Ghostty on Omarchy. |
| [`ghostty/macos/config`](ghostty/macos/config) | Ghostty on macOS: Brian's Mac settings plus the portable Omarchy settings. |
| [`ghostty/themes/`](ghostty/themes) | Monokai SublimeText theme, used on every machine. |
| [`profiles/`](profiles) | Per-machine settings: shell startup file, workspace directory, optional packages. |
| [`install.sh`](install.sh) | Links everything into `$HOME` for one profile. |

## Quick start

On macOS, install Homebrew and the Xcode Command Line Tools first. A work Mac without admin access needs Homebrew provisioned by IT.

```bash
git clone https://github.com/brian-nunez/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
./install.sh omarchy                       # preview the changes
./install.sh omarchy --apply               # link the configuration
./install.sh omarchy --apply --packages    # also install packages
```

Replace `omarchy` with `mac-personal` or `mac-work` on a Mac. The installer refuses to run a profile on the wrong platform. Open a new terminal afterwards to load the shell changes.

## What the installer does

- **Shell.** Adds this block to `~/.bashrc` (Omarchy) or `~/.zshrc` (macOS), replacing any older `source .../shell-scripts/init.sh` line:

  ```bash
  # >>> dotfiles >>>
  export WORKSPACE_DIR="$HOME/workspace"
  source "$HOME/workspace/dotfiles/shell-scripts/init.sh"
  # <<< dotfiles <<<
  ```

- **tmux and Ghostty.** Links `~/.config/tmux/tmux.conf`, `~/.config/ghostty/config` and the Ghostty theme. On macOS it warns when `~/Library/Application Support/com.mitchellh.ghostty/config` exists, because that file loads afterwards and overrides these settings.
- **Agents.** Runs `dotagents/install.sh` to link agent instructions and skills, backing up any real instruction files it would replace.
- **Packages.** With `--packages`, installs packages with pacman (Omarchy, only the ones missing) or Homebrew (macOS). The work profile installs apps into `~/Applications`.

## Profiles

| Setting | `omarchy` | `mac-personal` | `mac-work` |
| --- | --- | --- | --- |
| Shell startup file | `~/.bashrc` | `~/.zshrc` | `~/.zshrc` |
| `WORKSPACE_DIR` (used by `goto`, `gtg`) | `~/workspace` | `~/Documents/workspace` | `~/Documents/workspace` |
| Tailscale | yes | yes | no |
| Arduino CLI | no | yes | no |
| Java 21 | no | no | yes |
| Ruby (rbenv) | no | no | no |
| Docker CLI | yes | yes | yes |

Shared defaults live in [`profiles/common.sh`](profiles/common.sh). To change a setting on one machine only, create `local/<profile>.sh`; the `local/` directory is ignored by git:

```bash
DOTFILES_RUBY=1
DOTFILES_WORKSPACE='$HOME/code'
```

Package flags: `DOTFILES_AGENTS`, `DOTFILES_DOCKER`, `DOTFILES_JAVA`, `DOTFILES_RUBY`, `DOTFILES_ARDUINO`, `DOTFILES_TAILSCALE`.

## Secrets

`shell-scripts/init.sh` loads `shell-scripts/secrets.sh` last if it exists. That file is ignored by git. Create it (or symlink it) on each machine; never commit it.

## Development

Format the setup scripts with [shfmt](https://github.com/mvdan/sh); settings come from [`.editorconfig`](.editorconfig). Imported files in `shell-scripts/` and `dotagents/` keep their original formatting.

```bash
shfmt -w install.sh profiles tests    # format the setup scripts
bash tests/install.sh                 # run the installer against temporary home directories
```
