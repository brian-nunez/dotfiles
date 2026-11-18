# dotfiles

Brian's shell environment, agent guidance and skills, tmux, and Ghostty for
Omarchy x86_64 and personal/work Apple Silicon Macs. No Nix required.
Git and Neovim are installed; their configuration is a future addition.

## First machine setup

Start with an installed Omarchy desktop or macOS with Git and Xcode Command Line
Tools. On Macs, install [Homebrew](https://docs.brew.sh/Installation) first.
A work Mac needs IT to provision Homebrew in its supported prefix with access for
your user; initial installation requires admin access. Some application installers
also require admin access. The scripts do not bypass these restrictions.

```bash
git clone https://github.com/brian-nunez/dotfiles.git "$HOME/workspace/dotfiles"
cd "$HOME/workspace/dotfiles"
./bootstrap.sh mac-work --packages                # preview only
./bootstrap.sh mac-work --apply --backup --packages
```

Choose `omarchy`, `mac-personal`, or `mac-work`. Do not use sudo for the bootstrap.
`--packages` is optional; without it only configuration is managed. Preview does
not install software or write configuration. Installation preserves conflicts
only when `--backup` is supplied; otherwise it stops before writing anything.
Backups mirror home-relative paths under `~/.local/state/dotfiles/backups/`.

Omarchy configures only `~/.bashrc`; both Mac profiles configure only `~/.zshrc`.
Startup files retain existing contents and receive one source line. To migrate a
standalone legacy source line, add `--migrate-shell --backup`. Recognized lines
are `source ~/shell-scripts/init.sh`, `source "$HOME/shell-scripts/init.sh"`, and
their `.` equivalents. Other legacy loader forms require manual review. Bootstrap
backs up the original startup file before replacement. Never load both environments. Legacy whole
skills-directory symlinks also need review before migrating. Individual skill
links preserve unrelated tool-installed skills. Disabling a feature skips future
management; it does not uninstall software or remove previously installed links.

## Profiles and optional tools

Shared defaults live in `profiles/common.sh`; profile files override them. Work
Mac disables Tailscale by default. To customize a machine, create the ignored
`local/mac-work.sh` (or the matching profile name):

```bash
DOTFILES_DOCKER=0
DOTFILES_ARDUINO=0
DOTFILES_AGENTS=0
```

Available boolean flags: `AGENTS`, `DOCKER`, `JAVA`, `RUBY`, `ARDUINO`,
`TAILSCALE`, `ARTCRAFT`, and `GHIDRA`, each prefixed `DOTFILES_`.
Overrides are trusted shell code, loaded during preview and shell startup.
Personal Mac and Omarchy share feature defaults; package names differ by OS.
Package lists are in `scripts/packages.sh`. Add new tools there deliberately.
Core packages: Git, Neovim, tmux, fzf, Go, Node/npm, Ghostty, Nerd Font.
Optional packages cover Java 21, Ruby tooling, Arduino CLI, Docker CLI/Compose,
and Tailscale. Artcraft/Ghidra integrations only discover existing installations.
Agent guidance does not install agent executables or log into services.

The Docker package supplies CLI/Compose only on Mac. Use an existing employer
provided container engine, or install and configure an approved engine separately.
On Linux, Docker service configuration remains an explicit administrator step.
Tailscale login/service setup, Ruby versions, Arduino board cores and AI tool
credentials are also manual. Node is supplied by the OS package manager; an
existing NVM installation is still loaded if present and can override that Node.
macOS Java uses Homebrew's Java 21 without requiring a system JVM symlink.

## Private configuration

Create `~/.config/dotfiles/secrets.sh` yourself. Only interactive shell startup
loads it. Bootstrap never imports it. During migration, shell startup falls back to your existing private
`~/shell-scripts/secrets.sh` when the new location is absent. It is never copied
into this repository. Move it to the new location yourself when ready. All files named `secrets.sh`
and the repository's `local/` directory are ignored. Never put secrets into
profiles, tracked files, or command arguments. Git identity is not set globally.

## Updates and recovery

Keep the clone in place: shell modules and skills refer to its absolute path.
After edits, preview/apply the chosen profile again. Open a new terminal for shell
changes. Reload tmux deliberately; Ghostty configuration applies on reload or in a
new window. Omarchy theme colors remain dynamically included on Linux.

To restore a backed-up file, inspect its matching path under the printed backup
directory. Move the installed destination aside, then move the backup into place.
Backups preserve original symlinks. Packages are not rolled back by file recovery.
Switching profiles does not uninstall excluded packages. To stop managing a config,
replace its symlink with a copy and remove its bootstrap entry.

## Validation

```bash
bash tests/bootstrap.sh
```

Tests run in temporary home directories with simulated host/package commands.
They cover all profiles, previews, repeat installs, conflicts, backups, unrelated
skills, exclusions and host mismatch. Real Mac package installation and UI behavior
must also be checked on both M3 laptops before claiming platform verification.
The scripts use Bash 3.2-compatible syntax for macOS; shell modules support Bash/Zsh.

## Layout and sources

- `bootstrap.sh`: configuration planning, preflight, backups and application.
- `profiles/`: shared and machine-role settings.
- `scripts/`: profile loader and native package installation.
- `shell/`: modules imported from Brian's Shell Scripts.
- `agents/`: unchanged guidance and skills imported from Brian's DotAgents.
- `config/`: tmux and shared/platform Ghostty settings.

Inspired by [thdxr/environment](https://github.com/thdxr/environment)'s symlinked
home configuration and [madflojo/dotfiles](https://github.com/madflojo/dotfiles)'
terminal and agent organization. Original repositories retain their history.
