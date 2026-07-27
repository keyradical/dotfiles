# dotfiles

| Host     | OS        |
|----------|-----------|
| `mac`    | macOS (aerospace) |
| `pc`     | Fedora desktop (Sway) |
| `laptop 2-in-1` | Fedora desktop (Sway) |
| (none)   | headless remote box (SSH / coder workspace) |

## Install

```bash
git clone git@github.com:keyradical/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install               # lean: shared configs only
./install mac           # adds AeroSpace
./install pc            # adds Sway + waybar + PC bindings
./install laptop        # adds Sway + waybar + laptop bindings
```

The choice is persisted to `~/.dotfiles-host`; subsequent `./install` re-uses it.

Re-runs are safe.

### What `./install` does and does not do

`./install` links the configs and installs the userspace runtime deps those
configs require unconditionally — dotbot, starship, the zsh plugins, and
TPM + tmux plugins. All sudo-free.

It does **not** install OS packages (zsh, tmux, neovim). Those
need a package manager and sudo, so they live in the bootstrap scripts below.
`./install` warns at the end if any are missing.

## Fresh machine

| Box | Run |
|-----|-----|
| Fedora desktop | `./fedora-install.sh` — packages + Sway stack, then `./install` |
| Ubuntu/Debian remote | `./ubuntu-install.sh` — terminal packages only, then `./install` |

`ubuntu-install.sh` is aimed at headless dev boxes. It also installs Neovim from the
official tarball into `/opt/nvim-linux64`, because apt's Neovim is too old for
this LazyVim config (22.04 ships 0.6.1, 24.04 ships 0.9.5; LazyVim needs 0.11+).

## Remote workflow

Run tmux **on the remote box, inside the SSH session** — not a local tmux
wrapping SSH. `tmux.conf` detects `$SSH_CONNECTION` and paints the status bar
red with the hostname, and `set-clipboard on` relays OSC 52 yanks from remote
nvim back to the local terminal's clipboard.

```bash
ssh -t <host> -- tmux new -A -s main    # -A attaches if it exists, else creates
```

One-time setup from the local kitty, or tmux refuses to start on the remote
with `missing or unsuitable terminal: xterm-kitty`:

```bash
infocmp -a xterm-kitty | ssh <host> -- tic -x -o '$HOME/.terminfo' /dev/stdin
```

If `chsh` is unavailable (common in containers), tmux panes inherit bash even
with zsh fully configured. `ubuntu-install.sh` handles this by appending a
`exec zsh -l` guard to `~/.bash_profile`.
