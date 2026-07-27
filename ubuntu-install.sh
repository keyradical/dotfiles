#!/usr/bin/env bash
#
# ubuntu-install.sh — bootstrap a headless Ubuntu/Debian box with the dotfiles.
#
# Aimed at remote dev boxes (coder workspaces, VMs, containers) reached over
# SSH. Unlike fedora-install.sh there is no desktop stack here: no Sway, no
# waybar, no fonts, no kitty. Terminal tooling only.
#
# Installs the OS packages that ./install cannot (they need a package manager
# and sudo), plus Neovim from the official tarball because Ubuntu's apt version
# is far too old for this LazyVim config. Then hands off to ./install, which
# handles linking, starship, zsh plugins and TPM.
#
# Usage:
#   ./ubuntu-install.sh
#
# Env vars for non-interactive mode:
#   DOTFILES_SET_SHELL=y|n   change the login shell to zsh (default: ask)

set -euo pipefail

DOTFILES_REPO="https://github.com/keyradical/dotfiles.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -d "${SCRIPT_DIR}/.git" ]]; then
    DOTFILES_DIR="${SCRIPT_DIR}"
else
    DOTFILES_DIR="${HOME}/.dotfiles"
fi

# Neovim goes here because config/zsh/zshrc adds /opt/nvim-linux64/bin to PATH.
# Upstream renamed the tarball to include the arch (nvim-linux-x86_64), so the
# extracted directory is moved to this fixed name to honour that contract.
NVIM_PREFIX="/opt/nvim-linux64"
NVIM_MIN_MINOR=11   # LazyVim requires Neovim 0.11+

info()  { printf '\r[ .. ] %s\n' "$*"; }
ok()    { printf '\r[ OK ] %s\n' "$*"; }
warn()  { printf '\r[WARN] %s\n' "$*" >&2; }
error() { printf '\r[FAIL] %s\n' "$*" >&2; }
die()   { error "$*"; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

ask_yes_no() {
    local prompt="$1" default="${2:-n}" env_var="${3:-}" answer

    if [[ -n "$env_var" && -n "${!env_var:-}" ]]; then
        case "${!env_var}" in
            [Yy]|[Yy][Ee][Ss]|1|[Tt][Rr][Uu][Ee]) return 0 ;;
            *) return 1 ;;
        esac
    fi

    # Non-interactive run (no TTY) uses the default. Written as an explicit
    # if/else because a bare failing [[ ]] here would trip `set -e` whenever
    # this function is called outside a condition context.
    if [[ ! -t 0 ]]; then
        if [[ "$default" == "y" ]]; then return 0; else return 1; fi
    fi

    if [[ "$default" == "y" ]]; then
        read -r -p "$prompt [Y/n] " answer
        answer="${answer:-Y}"
    else
        read -r -p "$prompt [y/N] " answer
        answer="${answer:-N}"
    fi

    [[ "$answer" =~ ^[Yy] ]]
}

# ─── Preflight ───────────────────────────────────────────────────────────────

command_exists apt-get || die "This script is for Debian/Ubuntu (no apt-get found)."

if [[ $EUID -eq 0 ]]; then
    die "Do not run this script as root. It will call sudo when needed."
fi

# Containers sometimes ship without sudo. Detect it now so the package and
# Neovim steps can be skipped with a clear message rather than failing halfway.
# A sudo that needs a password is fine — it will prompt when used.
SUDO=""
if command_exists sudo; then
    SUDO="sudo"
fi

# pipx installs into ~/.local/bin, which Ubuntu only adds to PATH from
# ~/.profile and only for login shells — so a freshly pipx-installed dotbot is
# invisible to this script (and to ./install) without this. zshenv adds it for
# interactive zsh, which is why the gap only shows up during bootstrap.
export PATH="${HOME}/.local/bin:${PATH}"

# ─── APT packages ────────────────────────────────────────────────────────────

install_apt_packages() {
    if [[ -z "$SUDO" ]]; then
        warn "sudo not available — skipping OS packages."
        warn "Ask your admin for: zsh tmux build-essential python3-yaml ncurses-term ripgrep"
        return 0
    fi

    local pkgs=(
        # ── shell / terminal ──
        zsh tmux less man-db ncurses-term

        # ── build toolchain (LazyVim compiles treesitter parsers) ──
        build-essential

        # ── vcs / net ──
        git curl wget ca-certificates gnupg

        # ── archives (Mason unpacks LSP servers) ──
        unzip zip tar

        # ── python (dotbot needs pipx; ./install needs PyYAML) ──
        python3 python3-pip python3-venv python3-yaml pipx

        # ── search / fuzzy find ──
        ripgrep fd-find fzf

        # ── misc ──
        jq xclip
    )

    info "Updating apt index..."
    $SUDO apt-get update -qq

    info "Installing packages via apt..."
    if $SUDO apt-get install -y --no-install-recommends "${pkgs[@]}"; then
        ok "Packages installed"
    else
        warn "Batch install failed; retrying individually..."
        for pkg in "${pkgs[@]}"; do
            $SUDO apt-get install -y --no-install-recommends "$pkg" \
                || warn "Failed to install $pkg (skipping)"
        done
        ok "Package install complete (some may have been skipped)"
    fi
}

# Ubuntu names the fd binary `fdfind` to avoid a clash with fdclone. Tools that
# shell out to `fd` (telescope, fzf-lua) will not find it under that name.
link_fd() {
    if command_exists fd; then
        return 0
    fi
    if ! command_exists fdfind; then
        return 0
    fi
    mkdir -p "${HOME}/.local/bin"
    ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd"
    ok "Linked fdfind -> ~/.local/bin/fd"
}

# ─── Neovim ──────────────────────────────────────────────────────────────────

# Ubuntu 22.04 ships Neovim 0.6.1 and 24.04 ships 0.9.5; this config is
# LazyVim, which needs 0.11+. Always prefer the official tarball.
nvim_version() {
    nvim --version 2>/dev/null | head -1 | sed -E 's/^NVIM v?//'
}

nvim_is_recent() {
    command_exists nvim || return 1

    local version major minor
    version="$(nvim_version)"
    major="${version%%.*}"
    minor="${version#*.}"
    minor="${minor%%.*}"

    # Dev builds look like 0.12.0-dev-1234+gabc, so only the leading integers
    # of each field are compared. Bail out if either field is unparseable.
    [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]] || return 1

    if (( major > 0 )); then
        return 0
    fi
    (( minor >= NVIM_MIN_MINOR ))
}

install_neovim() {
    if nvim_is_recent; then
        ok "neovim $(nvim_version) already installed"
        return 0
    fi

    if [[ -z "$SUDO" ]]; then
        warn "sudo not available — cannot install neovim to $NVIM_PREFIX. Skipping."
        return 0
    fi

    local arch tarball
    arch="$(uname -m)"
    case "$arch" in
        x86_64)          tarball="nvim-linux-x86_64.tar.gz" ;;
        aarch64|arm64)   tarball="nvim-linux-arm64.tar.gz" ;;
        *) warn "No Neovim tarball for arch '$arch' — skipping."; return 0 ;;
    esac

    local tmpdir
    tmpdir="$(mktemp -d)"

    info "Downloading Neovim ($tarball)..."
    if ! curl -fsSL -o "${tmpdir}/${tarball}" \
        "https://github.com/neovim/neovim/releases/latest/download/${tarball}"; then
        rm -rf "$tmpdir"
        warn "Neovim download failed — skipping."
        return 0
    fi

    info "Installing Neovim to $NVIM_PREFIX..."
    tar -C "$tmpdir" -xzf "${tmpdir}/${tarball}"

    local extracted
    extracted="$(find "$tmpdir" -maxdepth 1 -type d -name 'nvim-linux*' | head -1)"
    if [[ -z "$extracted" ]]; then
        rm -rf "$tmpdir"
        warn "Unexpected tarball layout — skipping."
        return 0
    fi

    $SUDO rm -rf "$NVIM_PREFIX"
    $SUDO mv "$extracted" "$NVIM_PREFIX"
    rm -rf "$tmpdir"

    # zshrc puts this on PATH, but this script runs under bash and the user may
    # invoke nvim before opening a new shell. A symlink in /usr/local/bin makes
    # it work either way.
    $SUDO ln -sf "${NVIM_PREFIX}/bin/nvim" /usr/local/bin/nvim

    # The release binaries are built against a recent glibc. Confirm it runs
    # rather than leaving a broken binary on PATH.
    if "${NVIM_PREFIX}/bin/nvim" --version >/dev/null 2>&1; then
        ok "neovim $("${NVIM_PREFIX}/bin/nvim" --version | head -1 | sed 's/^NVIM v//') installed"
    else
        warn "Neovim installed but will not run (likely glibc too old for the latest release)."
        warn "Check: ${NVIM_PREFIX}/bin/nvim --version"
    fi
}

# ─── Dotfiles ────────────────────────────────────────────────────────────────

install_dotfiles() {
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        info "Dotfiles repo already present at $DOTFILES_DIR"
        git -C "$DOTFILES_DIR" pull --ff-only || warn "Could not update dotfiles"
    else
        info "Cloning dotfiles..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi

    # No host arg: lean install. Sway and AeroSpace overlays are desktop-only.
    info "Running dotbot installer (lean)..."
    "$DOTFILES_DIR/install"
}

# ─── Login shell ─────────────────────────────────────────────────────────────

# tmux panes inherit $SHELL. If the login shell stays bash, every pane comes up
# in bash even though zsh is fully configured.
set_login_shell() {
    local zsh_path
    zsh_path="$(command -v zsh || true)"
    if [[ -z "$zsh_path" ]]; then
        warn "zsh not installed — skipping login shell change"
        return 0
    fi

    if [[ "${SHELL:-}" == "$zsh_path" ]]; then
        ok "Login shell already zsh"
        return 0
    fi

    if ! ask_yes_no "Change the login shell to zsh?" "y" DOTFILES_SET_SHELL; then
        ok "Login shell unchanged"
        return 0
    fi

    if chsh -s "$zsh_path" 2>/dev/null; then
        ok "Login shell set to zsh (takes effect on next login)"
        return 0
    fi

    # chsh needs a writable /etc/passwd and working PAM, neither of which is a
    # given in a container. Hand off to bash instead.
    warn "chsh failed (common in containers). Falling back to a bash handoff."
    if ! grep -q 'exec zsh -l' "${HOME}/.bash_profile" 2>/dev/null; then
        cat >> "${HOME}/.bash_profile" <<'GUARD'

# Added by ubuntu-install.sh: hand off to zsh when chsh is unavailable.
[ -z "$ZSH_VERSION" ] && command -v zsh >/dev/null && exec zsh -l
GUARD
        ok "Added zsh handoff to ~/.bash_profile"
    else
        ok "zsh handoff already in ~/.bash_profile"
    fi
}

# ─── Main ────────────────────────────────────────────────────────────────────

echo ""
echo "  Dotfiles bootstrap — headless Ubuntu/Debian"
echo "  ==========================================="
echo ""

install_apt_packages
link_fd
install_neovim
install_dotfiles
set_login_shell

echo ""
ok "Bootstrap complete."
echo ""
echo "  Next steps:"
echo "    1. Log out and back in (or run: exec zsh -l)"
echo "    2. Run nvim once to let lazy.nvim install plugins"
echo ""
echo "  From your local kitty, fix terminfo once so tmux can start:"
echo "    infocmp -a xterm-kitty | ssh <host> -- tic -x -o '\$HOME/.terminfo' /dev/stdin"
echo ""
echo "  Then connect with:"
echo "    ssh -t <host> -- tmux new -A -s main"
echo ""
echo "  Not installed (add if you need them): node/npm, gh, docker."
echo ""
