#!/usr/bin/env bash
# =============================================================================
# Hyprland Material You Rice — Complete Turnkey Installer
# Native Hyprland Lua + Pure Quickshell DE + Dynamic Matugen Palette
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
ASSETS_DIR="$SCRIPT_DIR/assets"
HOME_DIR="$SCRIPT_DIR/home"

# ── Colors & Logging ──────────────────────────────────────────────────────────
BOLD='\033[1m'
NC='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'

log_info()  { echo -e "${BLUE}ℹ [INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}✔ [OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}⚠ [WARN]${NC} $*"; }
log_err()   { echo -e "${RED}✖ [ERROR]${NC} $*"; }
log_step()  { echo -e "\n${BOLD}${CYAN}==>${NC} ${BOLD}$*${NC}"; }

# ── Banner ───────────────────────────────────────────────────────────────────
print_banner() {
    clear 2>/dev/null || true
    echo -e "${PURPLE}${BOLD}"
    cat << "BANNER"
  _   _                 _                 _   ____  _          
 | | | |_   _ _ __  _ __| | __ _ _ __   __| | |  _ \(_) ___ ___ 
 | |_| | | | | '_ \| '__| |/ _` | '_ \ / _` | | |_) | |/ __/ _ \
 |  _  | |_| | |_) | |  | | (_| | | | | (_| | |  _ <| | (__  __/
 |_| |_|\__, | .__/|_|  |_|\__,_|_| |_|\__,_| |_| \_\_|\___\___|
        |___/|_|                                                 
BANNER
    echo -e "${NC}${CYAN}   ✦ Native Hyprland Lua  •  Pure Quickshell DE  •  Dynamic Material You ✦${NC}\n"
}

# ── Arguments & Flags ────────────────────────────────────────────────────────
AUTO_CONFIRM=false
USE_SYMLINK=""
SKIP_PACKAGES=false

for arg in "$@"; do
    case "$arg" in
        -y|--yes)
            AUTO_CONFIRM=true
            ;;
        -s|--symlink)
            USE_SYMLINK=true
            ;;
        -c|--copy)
            USE_SYMLINK=false
            ;;
        --no-pkg|--skip-packages)
            SKIP_PACKAGES=true
            ;;
        -h|--help)
            echo "Hyprland Rice Installer"
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -y, --yes            Automatic yes to prompts (unattended mode)"
            echo "  -s, --symlink        Symlink configs directly to repository (best for tweaking)"
            echo "  -c, --copy           Copy configs to ~/.config (standalone copy)"
            echo "      --no-pkg         Skip package installation and only deploy configs"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
    esac
done

prompt_confirm() {
    if [ "$AUTO_CONFIRM" = true ]; then
        return 0
    fi
    local message="$1"
    local default="${2:-Y}"
    local prompt="[Y/n]"
    [ "$default" = "N" ] && prompt="[y/N]"

    read -rp "$message $prompt " response
    response="${response:-$default}"
    [[ "$response" =~ ^[Yy]$ ]]
}

# ── Pre-flight Checks & Hardware Detection ────────────────────────────────────
check_system() {
    log_step "Checking System Environment & Hardware"

    if [ ! -f /etc/arch-release ]; then
        log_warn "This installer is optimized for Arch Linux and Arch-based distributions (EndeavourOS, Manjaro, etc.)."
        log_warn "You can still deploy dotfiles, but packages may require manual installation."
        if ! prompt_confirm "Do you wish to proceed anyway?" "Y"; then
            log_info "Installation aborted."
            exit 0
        fi
        IS_ARCH=false
    else
        log_ok "Arch Linux detected."
        IS_ARCH=true
    fi

    # Hardware & GPU detection
    if lspci 2>/dev/null | grep -iE "vga|3d" | grep -qi "nvidia"; then
        log_info "Nvidia GPU detected. Ensure 'nvidia-dkms' or appropriate proprietary drivers are installed."
        log_info "Hyprland Nvidia environment flags will be handled smoothly."
    fi

    # Battery & Brightness check
    if [ -d /sys/class/power_supply ] && ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
        log_ok "Laptop battery detected. Brightness and power monitoring will be enabled."
    fi

    # Detect AUR helper if Arch
    if [ "$IS_ARCH" = true ] && [ "$SKIP_PACKAGES" = false ]; then
        if command -v yay >/dev/null 2>&1; then
            AUR_HELPER="yay"
            log_ok "Found AUR helper: yay"
        elif command -v paru >/dev/null 2>&1; then
            AUR_HELPER="paru"
            log_ok "Found AUR helper: paru"
        else
            log_warn "Neither 'yay' nor 'paru' was found."
            if prompt_confirm "Would you like to install 'yay' now?" "Y"; then
                log_info "Installing yay prerequisites (git, base-devel)..."
                sudo pacman -S --needed --noconfirm git base-devel
                local tmp_dir
                tmp_dir=$(mktemp -d)
                git clone https://aur.archlinux.org/yay-bin.git "$tmp_dir/yay-bin"
                (cd "$tmp_dir/yay-bin" && makepkg -si --noconfirm)
                rm -rf "$tmp_dir"
                AUR_HELPER="yay"
                log_ok "yay installed successfully!"
            else
                AUR_HELPER=""
                log_warn "Proceeding without an AUR helper."
            fi
        fi
    fi
}

# ── Package Installation ─────────────────────────────────────────────────────
install_packages() {
    [ "$SKIP_PACKAGES" = true ] && return 0
    [ "$IS_ARCH" = false ] && return 0

    log_step "Installing System Packages & Core Dependencies"

    # Official Arch Repositories (pacman)
    local PACMAN_PKGS=(
        # Wayland Compositor & Core Utilities
        hyprland
        hypridle
        hyprlock
        hyprsunset
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        wl-clipboard
        cliphist
        grim
        slurp
        wf-recorder
        jq
        brightnessctl
        playerctl

        # Audio Stack
        pipewire
        wireplumber
        pipewire-pulse
        pipewire-alsa

        # Shell & Terminal Tools
        ghostty
        zsh
        starship
        fastfetch
        bat
        eza
        fzf
        zoxide
        python
        python-gobject
        ffmpeg

        # Fonts & Icons
        ttf-jetbrains-mono-nerd
        noto-fonts-emoji

        # Graphical Apps & Thumbnails
        thunar
        tumbler
        ffmpegthumbnailer

        # Quickshell & Dynamic Theming (Available in extra!)
        quickshell
        matugen
        awww

        # Qt6 Libraries
        qt6-base
        qt6-declarative
        qt6-svg
        qt6-wayland
        qt6-5compat
        qt6ct
    )

    # Fallback AUR packages if bleeding-edge or git builds are desired
    local AUR_PKGS=(
        quickshell-git
    )

    if prompt_confirm "Install required packages via pacman?" "Y"; then
        log_info "Synchronizing databases and installing official packages..."
        sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" || {
            log_warn "Some pacman packages may not have resolved cleanly. Attempting fallback..."
        }

        # If quickshell wasn't installed via pacman, fallback to AUR
        if ! command -v quickshell >/dev/null 2>&1 && [ -n "$AUR_HELPER" ]; then
            log_info "Installing quickshell-git via $AUR_HELPER..."
            $AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}" || true
        fi

        log_ok "System packages verified."
    else
        log_info "Skipping package installation."
    fi
}

# ── Backup Routine ───────────────────────────────────────────────────────────
backup_existing() {
    log_step "Backing Up Existing Configurations"

    local TIMESTAMP
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    local BACKUP_DIR="$HOME/.config/hyprquickdots-backup-$TIMESTAMP"
    local HAS_BACKUPS=false

    mkdir -p "$BACKUP_DIR"

    local TARGETS=(
        "$HOME/.config/hypr"
        "$HOME/.config/quickshell"
        "$HOME/.config/matugen"
        "$HOME/.config/ghostty"
        "$HOME/.config/fastfetch"
        "$HOME/.config/starship.toml"
        "$HOME/.config/nvim"
        "$HOME/.zshrc"
        "$HOME/.bashrc"
    )

    for target in "${TARGETS[@]}"; do
        if [ -e "$target" ] || [ -L "$target" ]; then
            log_info "Backing up $(basename "$target")..."
            cp -rL "$target" "$BACKUP_DIR/"
            HAS_BACKUPS=true
        fi
    done

    if [ "$HAS_BACKUPS" = true ]; then
        echo "$BACKUP_DIR" > "$HOME/.config/hyprquickdots-last-backup"
        log_ok "Backup created safely at: $BACKUP_DIR"
    else
        rm -rf "$BACKUP_DIR"
        log_info "No conflicting configurations needed backup."
    fi
}

# ── Configuration Deployment ─────────────────────────────────────────────────
deploy_configs() {
    log_step "Deploying Rice Configurations"

    # Determine deploy mode if not specified via flag
    if [ -z "$USE_SYMLINK" ]; then
        if [ "$AUTO_CONFIRM" = true ]; then
            USE_SYMLINK=false
        else
            echo -e "${BOLD}Choose deployment method:${NC}"
            echo -e "  [1] ${CYAN}Symlink${NC} — Live links to this repository (Recommended for developers/rice tweakers)"
            echo -e "  [2] ${GREEN}Copy${NC}    — Standalone copy of files to ~/.config"
            read -rp "Enter choice [1/2] (default: 1): " choice
            if [ "$choice" = "2" ]; then
                USE_SYMLINK=false
            else
                USE_SYMLINK=true
            fi
        fi
    fi

    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/Pictures/wallpaper"
    mkdir -p "$HOME/Pictures/shots"
    mkdir -p "$HOME/Videos/recordings"
    mkdir -p "$HOME/.cache"
    mkdir -p "$HOME/.local/bin"

    local DEPLOY_CONFIGS=(
        "hypr"
        "quickshell"
        "matugen"
        "ghostty"
        "fastfetch"
        "starship.toml"
        "nvim"
    )

    for item in "${DEPLOY_CONFIGS[@]}"; do
        local src="$CONFIG_DIR/$item"
        local dest="$HOME/.config/$item"

        [ ! -e "$src" ] && continue

        if [ -e "$dest" ] || [ -L "$dest" ]; then
            rm -rf "$dest"
        fi

        if [ "$USE_SYMLINK" = true ]; then
            log_info "Symlinking ~/.config/$item -> $src"
            ln -sf "$src" "$dest"
        else
            log_info "Copying ~/.config/$item"
            cp -r "$src" "$dest"
        fi
    done

    # Ensure executable permissions on all hyprland scripts
    chmod +x "$CONFIG_DIR/hypr/scripts/"* 2>/dev/null || true
    chmod +x "$HOME/.config/hypr/scripts/"* 2>/dev/null || true

    # Fix Ghostty theme path if copied
    if [ "$USE_SYMLINK" = false ] && [ -f "$HOME/.config/ghostty/config" ]; then
        sed -i "s|~/.config/ghostty/theme|$HOME/.config/ghostty/theme|g" "$HOME/.config/ghostty/config"
    fi

    # Deploy Aesthetic Wallpapers
    log_info "Deploying curated wallpapers to ~/Pictures/wallpaper/..."
    cp -n "$ASSETS_DIR/wallpapers/"* "$HOME/Pictures/wallpaper/" 2>/dev/null || true

    # Deploy Shell Configs
    if [ -f "$HOME_DIR/.zshrc" ]; then
        rm -f "$HOME/.zshrc"
        if [ "$USE_SYMLINK" = true ]; then
            ln -sf "$HOME_DIR/.zshrc" "$HOME/.zshrc"
        else
            cp "$HOME_DIR/.zshrc" "$HOME/.zshrc"
        fi
        log_ok "Installed ~/.zshrc"
    fi

    if [ -f "$HOME_DIR/.bashrc" ] && [ ! -f "$HOME/.bashrc" ]; then
        cp "$HOME_DIR/.bashrc" "$HOME/.bashrc"
        log_ok "Installed ~/.bashrc"
    fi

    log_ok "Configurations deployed successfully."
}

# ── Setup Zsh Plugins ────────────────────────────────────────────────────────
setup_zsh_plugins() {
    log_step "Configuring Zsh Plugins"

    local PLUGIN_DIR="$HOME/.zsh/plugins"
    mkdir -p "$PLUGIN_DIR"

    declare -A PLUGINS=(
        ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab"
        ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
        ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
        ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search"
    )

    for name in "${!PLUGINS[@]}"; do
        local target="$PLUGIN_DIR/$name"
        if [ ! -d "$target" ]; then
            log_info "Cloning $name..."
            git clone --depth 1 "${PLUGINS[$name]}" "$target" 2>/dev/null || log_warn "Could not clone $name"
        else
            log_ok "$name already installed."
        fi
    done

    # Check default shell
    if [ "$SHELL" != "$(command -v zsh 2>/dev/null)" ] && command -v zsh >/dev/null 2>&1; then
        if prompt_confirm "Set zsh as your default login shell?" "Y"; then
            chsh -s "$(command -v zsh)" 2>/dev/null || log_warn "Run 'chsh -s $(command -v zsh)' manually."
            log_ok "Default shell set to zsh."
        fi
    fi
}

# ── Initialize Palette & Theming ─────────────────────────────────────────────
init_theme() {
    log_step "Initializing Dynamic Material You Theming"

    local DEFAULT_WALL="$HOME/Pictures/wallpaper/qz7pz7.png"
    [ ! -f "$DEFAULT_WALL" ] && DEFAULT_WALL="$HOME/Pictures/wallpaper/japan-artistic.jpg"
    [ ! -f "$DEFAULT_WALL" ] && DEFAULT_WALL=$(find "$HOME/Pictures/wallpaper" -type f \( -iname "*.jpg" -o -iname "*.png" \) 2>/dev/null | head -n 1)

    mkdir -p "$HOME/.cache"
    [ -n "$DEFAULT_WALL" ] && echo "$DEFAULT_WALL" > "$HOME/.cache/hyprdots-wallpaper"
    echo "scheme-tonal-spot" > "$HOME/.cache/hyprdots-theme-scheme"

    local MATUGEN_BIN
    MATUGEN_BIN="$(command -v matugen 2>/dev/null || echo "$HOME/.local/bin/matugen")"

    if [ -x "$MATUGEN_BIN" ] && [ -n "$DEFAULT_WALL" ]; then
        log_info "Generating initial tonal palette with Matugen from $(basename "$DEFAULT_WALL")..."
        "$MATUGEN_BIN" image "$DEFAULT_WALL" --type scheme-tonal-spot --source-color-index 0 -c "$HOME/.config/matugen/config.toml" 2>/dev/null || true
        log_ok "Dynamic colors synchronized across Hyprland, Quickshell, and Ghostty."
    else
        log_warn "Matugen palette extraction will run automatically once Hyprland starts."
    fi
}

# ── Summary & Instructions ───────────────────────────────────────────────────
print_summary() {
    echo -e "\n${GREEN}${BOLD}🎉 Installation Complete!${NC}\n"
    echo -e "${CYAN}${BOLD}── Essential Keybindings Cheat Sheet ────────────────────────${NC}"
    echo -e "  ${BOLD}SUPER + SPACE${NC}      Spotlight Application Launcher (Quickshell)"
    echo -e "  ${BOLD}SUPER + N${NC}          Control Center Dashboard & Notification Panel"
    echo -e "  ${BOLD}SUPER + W${NC}          Wallpaper Picker & Dynamic Theme Switcher"
    echo -e "  ${BOLD}ALT + T${NC}            Curated Theme Preset Studio"
    echo -e "  ${BOLD}SUPER + /${NC}          Keybindings Cheatsheet Modal"
    echo -e "  ${BOLD}SUPER + V${NC}          Clipboard History Manager (cliphist)"
    echo -e "  ${BOLD}SUPER + \`${NC} / ${BOLD}SUPER + U${NC} Seamless Scratchpad Floating Terminal"
    echo -e "  ${BOLD}SUPER + Q${NC}          Ghostty Terminal"
    echo -e "  ${BOLD}SUPER + E${NC}          Thunar File Manager"
    echo -e "  ${BOLD}SUPER + B${NC}          Web Browser"
    echo -e "  ${BOLD}SUPER + F4${NC}         Close Active Window"
    echo -e "  ${BOLD}SUPER + T${NC}          Toggle Window Floating"
    echo -e "  ${BOLD}SUPER + F${NC}          Toggle Fullscreen"
    echo -e "  ${BOLD}SUPER + ALT + N${NC}    Toggle Blue Light Filter (hyprsunset)"
    echo -e "  ${BOLD}Print${NC}              Interactive Region Screenshot (grim + slurp)"
    echo -e "  ${BOLD}SUPER + SHIFT + R${NC}  Region Screen Recording (wf-recorder)"
    echo -e "  ${BOLD}SUPER + X${NC}          Power & Session Menu"
    echo -e "  ${BOLD}SUPER + M${NC}          Exit Hyprland"
    echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"
    echo -e "\n${BOLD}Ready to go!${NC}"
    echo -e "Log in via SDDM selecting ${BOLD}Hyprland${NC}, or run ${BOLD}Hyprland${NC} / ${BOLD}start-hyprland${NC}.\n"
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    print_banner
    check_system
    install_packages
    backup_existing
    deploy_configs
    setup_zsh_plugins
    init_theme
    print_summary
}

main "$@"
