#!/usr/bin/env bash
#
# fedora-install.sh — bootstrap a fresh Fedora install with Sway, dotfiles,
# and optional laptop/2-in-1 features.
#
# Computer-agnostic: works on desktop, laptop, and 2-in-1 convertibles.
# Interactive by default; set env vars for non-interactive mode:
#   SWAY_IS_LAPTOP=y|n
#   SWAY_IS_CONVERTIBLE=y|n
#   SWAY_IS_ASUS_ROG=y|n
#   SWAY_NVIDIA_GPU=y|n
#   SWAY_ENABLE_LID_SUSPEND=y|n
#   SWAY_ENABLE_TOUCHPAD=y|n
#   SWAY_NIGHT_LIGHT=y|n
#   SWAY_NIGHT_LIGHT_LAT=52.2
#   SWAY_NIGHT_LIGHT_LON=21.0
#
# Usage:
#   ./fedora-install.sh

set -euo pipefail

DOTFILES_REPO="https://github.com/keyradical/dotfiles.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -d "${SCRIPT_DIR}/.git" ]]; then
    DOTFILES_DIR="${SCRIPT_DIR}"
else
    DOTFILES_DIR="${HOME}/.dotfiles"
fi

ZSH_PLUGINS_DIR="${HOME}/.local/share/zsh/plugins"
TPM_DIR="${HOME}/.config/tmux/plugins/tpm"

info()  { printf '\r[ .. ] %s\n' "$*"; }
ok()    { printf '\r[ OK ] %s\n' "$*"; }
warn()  { printf '\r[WARN] %s\n' "$*" >&2; }
error() { printf '\r[FAIL] %s\n' "$*" >&2; }
die()   { error "$*"; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }
has_rpm_pkg() { rpm -q "$1" >/dev/null 2>&1; }

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local answer
    local env_var="${3:-}"

    # Check for env var override
    if [[ -n "$env_var" && -n "${!env_var:-}" ]]; then
        local val="${!env_var}"
        case "$val" in
            [Yy]|[Yy][Ee][Ss]|1|[Tt][Rr][Uu][Ee]) return 0 ;;
            *) return 1 ;;
        esac
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

ask_value() {
    local prompt="$1"
    local default="$2"
    local env_var="${3:-}"
    local answer

    if [[ -n "$env_var" && -n "${!env_var:-}" ]]; then
        printf '%s' "${!env_var}"
        return 0
    fi

    read -r -p "$prompt [${default}] " answer
    printf '%s' "${answer:-$default}"
}

if [[ ! -f /etc/fedora-release ]]; then
    die "This script is for Fedora only."
fi

if [[ $EUID -eq 0 ]]; then
    die "Do not run this script as root. It will call sudo when needed."
fi

# Safety check: warn if running from inside a graphical session
if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" ]]; then
    echo ""
    echo "  ⚠️  WARNING: You appear to be running this from inside a graphical session."
    echo "      sudo dnf operations may restart services and log you out."
    echo ""
    echo "      RECOMMENDED: Switch to a text console first:"
    echo "          1. Press Ctrl+Alt+F3"
    echo "          2. Log in there"
    echo "          3. Run this script"
    echo ""
    if ! ask_yes_no "Continue anyway?" "n"; then
        echo "Aborted. Please switch to a TTY (Ctrl+Alt+F3) and run again."
        exit 1
    fi
fi

# ─── Interactive questions ───────────────────────────────────────────────────

echo ""
echo "  Sway on Fedora — Setup Questions"
echo "  =================================="
echo ""
echo "  (Set env vars to skip interactively, e.g. SWAY_IS_LAPTOP=y)"
echo ""

IS_LAPTOP=0
IS_CONVERTIBLE=0
IS_ASUS_ROG=0
IS_NVIDIA_GPU=0
ENABLE_LID_SUSPEND=0
ENABLE_TOUCHPAD=0
ENABLE_NIGHT_LIGHT=0
NIGHT_LIGHT_LAT="52.2"
NIGHT_LIGHT_LON="21.0"

if ask_yes_no "Is this a laptop?" "n" "SWAY_IS_LAPTOP"; then
    IS_LAPTOP=1

    if ask_yes_no "Enable lid-close suspend?" "y" "SWAY_ENABLE_LID_SUSPEND"; then
        ENABLE_LID_SUSPEND=1
    fi

    if ask_yes_no "Enable touchpad tap-to-click and natural scroll?" "y"; then
        ENABLE_TOUCHPAD=1
    fi

    if ask_yes_no "Is this a 2-in-1 convertible (e.g. Surface, Yoga, Flow X13)?" "n" "SWAY_IS_CONVERTIBLE"; then
        IS_CONVERTIBLE=1
    fi

    if ask_yes_no "Is this an ASUS ROG laptop?" "n" "SWAY_IS_ASUS_ROG"; then
        IS_ASUS_ROG=1
    fi
fi

if ask_yes_no "Enable night light (reduces blue light at night)?" "y" "SWAY_NIGHT_LIGHT"; then
    ENABLE_NIGHT_LIGHT=1
    NIGHT_LIGHT_LAT="$(ask_value "Night light latitude" "52.2" "SWAY_NIGHT_LIGHT_LAT")"
    NIGHT_LIGHT_LON="$(ask_value "Night light longitude" "21.0" "SWAY_NIGHT_LIGHT_LON")"
fi

if ask_yes_no "Install NVIDIA open-source GPU driver and CUDA toolkit?" "n" "SWAY_NVIDIA_GPU"; then
    IS_NVIDIA_GPU=1
fi

echo ""

# ─── RPM Fusion ──────────────────────────────────────────────────────────────

enable_rpm_fusion() {
    local ver
    ver="$(rpm -E %fedora)"
    local changed=0

    if ! has_rpm_pkg rpmfusion-free-release; then
        info "Enabling RPM Fusion free repository..."
        sudo dnf install -y \
            "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${ver}.noarch.rpm"
        changed=1
    fi

    if ! has_rpm_pkg rpmfusion-nonfree-release; then
        info "Enabling RPM Fusion nonfree repository..."
        sudo dnf install -y \
            "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${ver}.noarch.rpm"
        changed=1
    fi

    if [[ "$changed" -eq 0 ]]; then
        ok "RPM Fusion already enabled"
    else
        ok "RPM Fusion enabled"
    fi
}

# ─── System update ───────────────────────────────────────────────────────────

update_system() {
    if ask_yes_no "Run system update (sudo dnf upgrade)?\n    WARNING: This may restart services and log you out.\n    Safer to skip if inside a graphical session." "n"; then
        info "Updating system packages..."
        sudo dnf upgrade -y
        ok "System updated"
    else
        ok "System update skipped"
    fi
}

# ─── DNF packages ────────────────────────────────────────────────────────────

install_dnf_packages() {
    info "Installing packages via dnf..."

    local pkgs=(
        # ── base / build ──
        git cmake ninja-build meson gcc gcc-c++ clang gdb llvm lld
        pciutils vala gobject-introspection-devel gtk4-devel libadwaita-devel

        # ── shell / terminal ──
        zsh tmux kitty fzf ripgrep fd-find wl-clipboard xclip less man-db

        # ── editor ──
        neovim

        # ── dev tools ──
        nodejs22-bin nodejs22-npm-bin python3 python3-pip pipx unzip zip tar curl wget2-wget
        gh

        # ── Sway / Wayland ──
        sway swaybg swayidle swaylock waybar fuzzel lxpolkit wlsunset
        xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk

        # ── notifications / system tray ──
        dunst libnotify network-manager-applet wlogout

        # ── utilities ──
        grim slurp brightnessctl ImageMagick playerctl upower
        power-profiles-daemon pavucontrol wdisplays

        # ── audio ──
        pipewire pipewire-pulseaudio pipewire-alsa wireplumber

        # ── bluetooth ──
        bluez

        # ── file manager + deps ──
        thunar dolphin breeze-icon-theme kio-extras gvfs gvfs-mtp gvfs-smb

        # ── fonts ──
        dejavu-sans-fonts dejavu-sans-mono-fonts jetbrains-mono-fonts
        google-noto-sans-fonts google-noto-emoji-fonts fontawesome-fonts-all

        # ── theming ──
        qt5ct qt6ct kvantum adw-gtk3-theme

        # ── xwayland / display ──
        xorg-x11-server-Xwayland mesa-dri-drivers mesa-libGL egl-wayland

        # ── extras ──
        nano
    )

    # Laptop-specific packages
    if [[ "$IS_LAPTOP" -eq 1 ]]; then
        pkgs+=(
            upower
            brightnessctl
        )
    fi

    # 2-in-1 convertible packages
    if [[ "$IS_CONVERTIBLE" -eq 1 ]]; then
        pkgs+=(
            iio-sensor-proxy
        )
    fi

    # ASUS ROG laptop packages
    if [[ "$IS_ASUS_ROG" -eq 1 ]]; then
        pkgs+=(
            asusctl
            asusctl-rog-gui
        )
    fi

    local to_install=()
    for pkg in "${pkgs[@]}"; do
        if ! has_rpm_pkg "$pkg"; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        ok "All packages already installed"
        return 0
    fi

    if sudo dnf install -y "${to_install[@]}"; then
        ok "Packages installed"
        return 0
    fi

    warn "Batch install failed; retrying individually..."
    for pkg in "${to_install[@]}"; do
        sudo dnf install -y "$pkg" || warn "Failed to install $pkg (skipping)"
    done
    ok "Package install complete (some may have been skipped)"
}

# ─── Starship ────────────────────────────────────────────────────────────────

install_starship() {
    if command_exists starship; then
        ok "starship already installed"
        return 0
    fi

    if has_rpm_pkg starship; then
        info "Installing starship from dnf..."
        sudo dnf install -y starship
        ok "starship installed"
        return 0
    fi

    info "Installing starship via official script..."
    mkdir -p "${HOME}/.local/bin"
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "${HOME}/.local/bin"
    ok "starship installed to ~/.local/bin"
}

# ─── Dotbot ──────────────────────────────────────────────────────────────────

install_dotbot() {
    if command_exists dotbot; then
        ok "dotbot already installed"
        return 0
    fi

    if command_exists pipx; then
        info "Installing dotbot via pipx..."
        pipx install dotbot
        ok "dotbot installed"
        return 0
    fi

    die "pipx is required to install dotbot but was not found"
}

# ─── Zsh plugins ─────────────────────────────────────────────────────────────

install_zsh_plugins() {
    info "Installing zsh plugins..."

    mkdir -p "$ZSH_PLUGINS_DIR"

    local plugins=(
        "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
        "zsh-history-substring-search|https://github.com/zsh-users/zsh-history-substring-search"
        "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting"
        "zsh-completions|https://github.com/zsh-users/zsh-completions"
    )

    for entry in "${plugins[@]}"; do
        local name="${entry%%|*}"
        local url="${entry##*|}"
        local dest="$ZSH_PLUGINS_DIR/$name"

        if [[ -d "$dest/.git" ]]; then
            info "Updating zsh plugin: $name"
            git -C "$dest" pull --ff-only
        else
            info "Cloning zsh plugin: $name"
            rm -rf "$dest"
            git clone --depth=1 "$url" "$dest"
        fi
    done

    ok "zsh plugins ready"
}

# ─── TPM ─────────────────────────────────────────────────────────────────────

install_tpm() {
    if [[ -d "$TPM_DIR/.git" ]]; then
        ok "TPM already installed"
        return 0
    fi

    if [[ -d "$TPM_DIR" ]]; then
        ok "TPM directory already present (skipping clone)"
        return 0
    fi

    info "Installing TPM..."
    mkdir -p "$(dirname "$TPM_DIR")"
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
    ok "TPM installed"
}

# ─── Dotfiles ──────────────────────────────────────────────────────────────────

install_dotfiles() {
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        info "Dotfiles repo already present at $DOTFILES_DIR"
        git -C "$DOTFILES_DIR" pull --ff-only || warn "Could not update dotfiles"
    else
        info "Cloning dotfiles..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi

    # Pass the host choice through to the unified installer.
    local host="pc"
    if [[ "$IS_LAPTOP" -eq 1 ]]; then
        host="laptop"
    fi

    info "Running dotbot installer (host=$host)..."
    DOTFILES_HOST="$host" "$DOTFILES_DIR/install"
    ok "Dotfiles linked"

    # Install tmux plugins if tpm exists but plugins are missing
    if [[ -d "$HOME/.config/tmux/plugins/tpm" && ! -d "$HOME/.config/tmux/plugins/tmux-sensible" ]]; then
        info "Installing tmux plugins via TPM..."
        "$HOME/.config/tmux/plugins/tpm/bin/install_plugins" || warn "TPM plugin install failed"
    fi
}

# ─── Generate machine-specific Sway config ─────────────────────────────────

generate_sway_local() {
    local file="$HOME/.config/sway/config.local"
    mkdir -p "$(dirname "$file")"

    {
        echo "# Machine-specific Sway config"
        echo "# Generated by fedora-install.sh on $(date)"
        echo "# Edit or delete as needed. Sway ignores this file if missing."
        echo ""
    } > "$file"

    if [[ "${ENABLE_TOUCHPAD:-0}" -eq 1 ]]; then
        {
            echo "# Touchpad"
            echo 'input "type:touchpad" {'
            echo "    tap enabled"
            echo "    natural_scroll enabled"
            echo "    pointer_accel 0.3"
            echo "}"
            echo ""
        } >> "$file"
    fi

    if [[ "$ENABLE_NIGHT_LIGHT" -eq 1 ]]; then
        {
            echo "# Night light (override default coordinates)"
            echo "# Default in base config is 52.2, 21.0 (Warsaw)"
            echo "# Uncomment below to set your own:"
            echo "# exec_always pkill -x wlsunset; wlsunset -l ${NIGHT_LIGHT_LAT} -L ${NIGHT_LIGHT_LON} -t 3500 -T 6500"
            echo ""
        } >> "$file"
    fi

    if [[ "$IS_CONVERTIBLE" -eq 1 ]]; then
        {
            echo "# Auto-rotate for 2-in-1 convertibles"
            echo 'exec_always pgrep -f "sway/scripts/autorotate" >/dev/null || $HOME/.config/sway/scripts/autorotate'
            echo ""
        } >> "$file"
    fi

    if [[ "$ENABLE_LID_SUSPEND" -eq 1 ]]; then
        {
            echo "# Lid close → suspend (handled by logind drop-in)"
            echo "# (Requires: HandleLidSwitch=suspend in /etc/systemd/logind.conf.d/)"
            echo ""
        } >> "$file"
    fi

    ok "Generated $file"
}

# ─── System services ─────────────────────────────────────────────────────────

setup_services() {
    info "Enabling user services..."

    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

    ok "User services enabled"
}

# ─── IIO sensor buffer (for 2-in-1 autorotate) ───────────────────────────────

setup_iio_buffer() {
    if [[ "$IS_CONVERTIBLE" -eq 0 ]]; then
        return 0
    fi

    if [[ -f /etc/systemd/system/enable-iio-buffer.service ]]; then
        ok "IIO buffer service already present"
        return 0
    fi

    info "Creating IIO accelerometer buffer service..."

    sudo tee /etc/systemd/system/enable-iio-buffer.service >/dev/null <<'EOF'
[Unit]
Description=Enable IIO accelerometer buffer
After=systemd-modules-load.service

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 5
ExecStart=/bin/sh -c 'echo 1 > /sys/bus/iio/devices/iio:device0/buffer/enable'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now enable-iio-buffer.service

    ok "IIO buffer service enabled"
}

# ─── Logind lid configuration ────────────────────────────────────────────────

setup_logind_lid() {
    if [[ "$ENABLE_LID_SUSPEND" -eq 0 ]]; then
        return 0
    fi

    info "Configuring logind lid-close behavior..."

    sudo mkdir -p /etc/systemd/logind.conf.d
    sudo tee /etc/systemd/logind.conf.d/lid-suspend.conf >/dev/null <<'EOF'
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
EOF

    sudo systemctl reload-or-restart systemd-logind || true
    ok "Logind lid-close → suspend (config reloaded)"
}

# ─── NVIDIA driver + CUDA ──────────────────────────────────────────────────

setup_nvidia() {
    if [[ "$IS_NVIDIA_GPU" -eq 0 ]]; then
        return 0
    fi

    # Detect distro and version
    local distro_name=""
    local distro_version=""
    local arch="x86_64"

    if [ -f /etc/os-release ]; then
        distro_name=$(source /etc/os-release && echo "$ID")
        distro_version=$(source /etc/os-release && echo "$VERSION_ID")
    fi

    # Fallback for Fedora
    if [ -z "$distro_version" ] && command -v rpm >/dev/null 2>&1; then
        distro_version=$(rpm -E '%fedora' 2>/dev/null || true)
    fi

    # Validate we have what we need
    if [ -z "$distro_name" ] || [ -z "$distro_version" ]; then
        die "Could not detect Linux distribution. NVIDIA driver installation aborted."
    fi

    if [ "$distro_name" != "fedora" ]; then
        warn "NVIDIA driver auto-install only supported on Fedora (detected: $distro_name). Skipping."
        return 0
    fi

    local repo_url="https://developer.download.nvidia.com/compute/cuda/repos/fedora${distro_version}/${arch}/cuda-fedora${distro_version}.repo"

    info "Checking NVIDIA repository for Fedora ${distro_version}..."

    # Check if repo exists before adding
    if ! curl -fsI "$repo_url" >/dev/null 2>&1; then
        warn "NVIDIA does not provide a repository for Fedora ${distro_version}."
        warn "Supported Fedora versions: https://developer.download.nvidia.com/compute/cuda/repos/"
        warn "Skipping NVIDIA driver installation."
        return 0
    fi

    info "Adding NVIDIA repository for Fedora ${distro_version}..."
    sudo dnf config-manager addrepo --from-repofile="$repo_url"
    sudo dnf clean expire-cache
    ok "NVIDIA repository added"

    info "Installing CUDA-compatible compiler (gcc15)..."
    sudo dnf install -y gcc15 gcc15-c++
    ok "gcc15 installed"

    info "Installing NVIDIA open kernel modules and CUDA toolkit..."
    sudo dnf install -y nvidia-open cuda-toolkit --allowerasing
    ok "NVIDIA driver and CUDA toolkit installed"
    warn "A REBOOT is required for the NVIDIA driver to load"
}

# ─── NVIDIA Sway workaround ──────────────────────────────────────────────────

setup_nvidia_sway() {
    if [[ "$IS_NVIDIA_GPU" -eq 0 ]]; then
        return 0
    fi

    info "Configuring Sway for NVIDIA/hybrid GPU setup..."

    mkdir -p "${HOME}/.local/bin"

    local wrapper="${HOME}/.local/bin/sway"
    cat > "$wrapper" <<'WRAPPER'
#!/usr/bin/env bash
# Sway launcher — forces Intel iGPU, bypasses NVIDIA proprietary check.
# Generated by fedora-install.sh

# Force Sway to use Intel GPU (card1) where the display is connected
export WLR_DRM_DEVICES=/dev/dri/card1

# Sway hard-exits if it sees nvidia-drm loaded, even if we tell it
# to use a different GPU. --unsupported-gpu bypasses that check.
exec /usr/bin/sway --unsupported-gpu "$@"
WRAPPER
    chmod +x "$wrapper"

    ok "Created Sway wrapper at ${wrapper}"
}

# ─── ASUS ROG laptop settings ─────────────────────────────────────────────

setup_asus() {
    if [[ "$IS_ASUS_ROG" -eq 0 ]]; then
        return 0
    fi

    info "Configuring ASUS power profile..."
    if command -v asusctl >/dev/null 2>&1; then
        asusctl profile set Balanced 2>/dev/null || warn "Could not set ASUS profile to Balanced"
    fi
    ok "ASUS profile set to Balanced"
}

# ─── Post-install hints ──────────────────────────────────────────────────────

print_next_steps() {
    if [[ "$IS_NVIDIA_GPU" -eq 1 ]]; then
        echo ""
        echo "  ⚠️  IMPORTANT: REBOOT REQUIRED for NVIDIA driver to load"
        echo ""
    fi

    cat <<'EOF'

╔══════════════════════════════════════════════════════════════════════════════╗
║                        INSTALLATION COMPLETE                                 ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  1. REBOOT so Sway and services take full effect.                            ║
║                                                                              ║
║  2. Select "Sway" from the login screen session menu.                        ║
║                                                                              ║
║  3. Sway idle policy:                                                        ║
║       • Lock after 5 minutes idle                                             ║
║       • Display off after 5m30s idle                                          ║
║       • Suspend after 15 minutes idle on battery                              ║
║                                                                              ║
║  4. If you want zsh as default shell:                                        ║
║       chsh -s $(command -v zsh)                                              ║
║                                                                              ║
║  5. In tmux, press `prefix + I` to install tmux plugins.                     ║
║                                                                              ║
║  6. Machine-specific Sway config is in ~/.config/sway/config.local          ║
║     (regenerate by re-running this script).                                 ║
║                                                                              ║
║  7. External monitor setup:                                                  ║
║       Run `wdisplays` to position monitors via GUI.                         ║
║       Saves to ~/.config/sway/config.local without breaking autorotate.       ║
║                                                                              ║
║  8. Authenticate GitHub CLI (to manage repos from terminal):                  ║
║       gh auth login                                                          ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF
}

# ─── Main ────────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo "  Fedora Sway Dotfiles Bootstrap"
    echo "  =============================="
    echo ""

    enable_rpm_fusion
    update_system
    install_dnf_packages
    install_starship
    install_dotbot
    install_zsh_plugins
    install_tpm
    install_dotfiles
    generate_sway_local
    setup_services
    setup_iio_buffer
    setup_logind_lid
    setup_nvidia
    setup_nvidia_sway
    setup_asus

    print_next_steps
}

main "$@"
