# dotfiles

| Host     | OS        |
|----------|-----------|
| `mac`    | macOS (AeroSpace) |
| `pc`     | Fedora desktop (Sway) |
| `laptop` | Fedora 2-in-1 (Swawy) |

## Install

```bash
git clone git@github.com:keyradical/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install               # mac auto-detects; linux prompts
./install pc            # or pass host explicitly
```

Fresh Fedora box: `./fedora-install.sh` instead — installs packages, then runs `./install`.

Re-runs are safe.
