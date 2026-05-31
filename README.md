# dotfiles

| Host     | OS        |
|----------|-----------|
| `mac`    | macOS (aerospace) |
| `pc`     | Fedora desktop (Sway) |
| `laptop 2-in-1` | Fedora desktop (Sway) |

## Install

```bash
git clone git@github.com:keyradical/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install               # lean: shared configs only (good for SSH boxes)
./install mac           # adds AeroSpace
./install pc            # adds Sway + waybar + PC bindings
./install laptop        # adds Sway + waybar + laptop bindings
```

The choice is persisted to `~/.dotfiles-host`; subsequent `./install` re-uses it.

Fresh Fedora box: `./fedora-install.sh` instead — installs packages, then runs `./install`.

Re-runs are safe.
