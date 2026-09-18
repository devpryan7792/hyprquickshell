#!/usr/bin/env bash
# =============================================================================
# Hyprland Rice — Complete Automated Installer
# Native Hyprland Lua + Pure Quickshell DE + Dynamic Matugen Material You
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
USE_SYMLINK=false

for arg in "$@"; do
    case "$arg" in
        -y|--yes)
            AUTO_CONFIRM=true
            ;;
        -s|--symlink)
            USE_SYMLINK=true
            ;;
        -h|--help)
            echo "Usage: ./install.sh [OPTIONS]"
            echo "Options:"
            echo "  -y, --yes      Automatic yes to prompts (unattended mode)"
            echo "  -s, --symlink  Symlink configs instead of copying (great for development)"
            echo "  -h, --help     Show this help message"
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

# ── Pre-flight Checks ────────────────────────────────────────────────────────
check_system() {
    log_step "Checking System Environment"
    
    if [ ! -f /etc/arch-release ]; then
        log_warn "This installer is tailored for Arch Linux and Arch-based systems."
        log_warn "You can still proceed with configuration deployment, but package installation may need to be done manually."
        if ! prompt_confirm "Do you wish to continue?" "Y"; then
            log_info "Installation aborted."
            exit 0
        fi
        IS_ARCH=false
    else
        log_ok "Arch Linux detected."
        IS_ARCH=true
    fi

    # Check for AUR helper if Arch
    if [ "$IS_ARCH" = true ]; then
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
                log_warn "Proceeding without an AUR helper. AUR packages must be installed manually."
            fi
        fi
    fi
}

# ── Package Installation ─────────────────────────────────────────────────────
install_packages() {
    log_step "Installing Dependencies"

    local PACMAN_PKGS=(
        hyprland
        hyprsunset
        wl-clipboard
        cliphist
        grim
        slurp
        jq
        brightnessctl
        playerctl
        pipewire
        wireplumber
        wf-recorder
        thunar
        ghostty
        zsh
        starship
        fastfetch
        bat
        eza
        fzf
        zoxide
        python
        ttf-jetbrains-mono-nerd
        qt6-base
        qt6-declarative
        qt6-svg
        qt6ct
    )

    local AUR_PKGS=(
        quickshell-git
        matugen-bin
        awww
    )

    if [ "$IS_ARCH" = true ]; then
        if prompt_confirm "Install required system and AUR packages?" "Y"; then
            log_info "Installing official repository packages via pacman..."
            sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

            if [ -n "$AUR_HELPER" ]; then
                log_info "Installing AUR packages via $AUR_HELPER..."
                $AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}"
            else
                log_warn "Please manually install the following AUR packages: ${AUR_PKGS[*]}"
            fi
            log_ok "Packages installed successfully."
        else
            log_info "Skipping package installation."
        fi
    fi
}

# ── Backup Routine ───────────────────────────────────────────────────────────
backup_existing() {
    log_step "Backing Up Existing Configurations"

    local TIMESTAMP
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    local BACKUP_DIR="$HOME/.config/hyprland-rice-backup-$TIMESTAMP"
    local HAS_BACKUPS=false

    mkdir -p "$BACKUP_DIR"

    local TARGETS=(
        "$HOME/.config/hypr"
        "$HOME/.config/quickshell"
        "$HOME/.config/matugen"
        "$HOME/.config/ghostty"
        "$HOME/.config/fastfetch"
        "$HOME/.config/starship.toml"
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
        echo "$BACKUP_DIR" > "$HOME/.config/hyprland-rice-last-backup"
        log_ok "Backup completed at: $BACKUP_DIR"
    else
        rm -rf "$BACKUP_DIR"
        log_info "No existing configurations needed backup."
    fi
}

# ── Deploy Configurations ────────────────────────────────────────────────────
deploy_configs() {
    log_step "Deploying Rice Configurations"

    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/Pictures/wallpaper"
    mkdir -p "$HOME/Pictures/shots"
    mkdir -p "$HOME/Videos/recordings"

    local DEPLOY_ITEMS=(
        "hypr"
        "quickshell"
        "matugen"
        "ghostty"
        "fastfetch"
        "starship.toml"
    )

    for item in "${DEPLOY_ITEMS[@]}"; do
        local src="$CONFIG_DIR/$item"
        local dest="$HOME/.config/$item"

        if [ -e "$dest" ] || [ -L "$dest" ]; then
            rm -rf "$dest"
        fi

        if [ "$USE_SYMLINK" = true ]; then
            log_info "Symlinking $item -> $dest"
            ln -s "$src" "$dest"
        else
            log_info "Copying $item -> $dest"
            cp -r "$src" "$dest"
        fi
    done

    # Ensure executable permissions on all hypr scripts
    chmod +x "$HOME/.config/hypr/scripts/"* 2>/dev/null || true

    # Fix Ghostty theme path to user's home directory
    if [ -f "$HOME/.config/ghostty/config" ]; then
        sed -i "s|~/.config/ghostty/theme|$HOME/.config/ghostty/theme|g" "$HOME/.config/ghostty/config"
        sed -i "s|/home/[^/]*/.config/ghostty/theme|$HOME/.config/ghostty/theme|g" "$HOME/.config/ghostty/config"
    fi

    # Deploy Wallpapers
    log_info "Deploying curated aesthetic wallpapers to ~/Pictures/wallpaper/..."
    cp -n "$ASSETS_DIR/wallpapers/"* "$HOME/Pictures/wallpaper/" 2>/dev/null || true

    # Deploy Shell Configs
    if [ -f "$HOME_DIR/.zshrc" ]; then
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
    log_step "Setting up Zsh Plugins"

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
            git clone --depth 1 "${PLUGINS[$name]}" "$target" 2>/dev/null || log_warn "Failed to clone $name"
        else
            log_ok "$name already installed."
        fi
    done
}

# ── Initialize Palette & Theming ─────────────────────────────────────────────
init_theme() {
    log_step "Initializing Dynamic Material You Palette"

    local DEFAULT_WALL="$HOME/Pictures/wallpaper/japan-artistic.jpg"
    [ ! -f "$DEFAULT_WALL" ] && DEFAULT_WALL=$(find "$HOME/Pictures/wallpaper" -type f \( -iname "*.jpg" -o -iname "*.png" \) | head -n 1)

    mkdir -p "$HOME/.cache"
    echo "$DEFAULT_WALL" > "$HOME/.cache/hyprdots-wallpaper"
    echo "scheme-tonal-spot" > "$HOME/.cache/hyprdots-theme-scheme"

    local MATUGEN_BIN
    MATUGEN_BIN="$(command -v matugen 2>/dev/null || echo "$HOME/.local/bin/matugen")"

    if [ -x "$MATUGEN_BIN" ] && [ -n "$DEFAULT_WALL" ]; then
        log_info "Running initial Matugen palette extraction on $(basename "$DEFAULT_WALL")..."
        "$MATUGEN_BIN" image "$DEFAULT_WALL" --type scheme-tonal-spot --source-color-index 0 -c "$HOME/.config/matugen/config.toml" 2>/dev/null || true
        log_ok "Dynamic colors generated for Hyprland, Quickshell, and Ghostty."
    else
        log_warn "Matugen binary not found in PATH or ~/.local/bin. Dynamic palette can be generated once installed."
    fi
}

# ── Summary & Instructions ───────────────────────────────────────────────────
print_summary() {
    echo -e "\n${GREEN}${BOLD}🎉 Installation Complete!${NC}\n"
    echo -e "${CYAN}${BOLD}── Keybinding Cheat Sheet ───────────────────────────────────${NC}"
    echo -e "  ${BOLD}SUPER + SPACE${NC}      Spotlight Application Launcher (Quickshell)"
    echo -e "  ${BOLD}SUPER + N${NC}          Control Center / Notification Dashboard"
    echo -e "  ${BOLD}SUPER + W${NC}          Wallpaper Picker & Dynamic Theme Switcher"
    echo -e "  ${BOLD}SUPER + V${NC}          Clipboard History Manager (cliphist)"
    echo -e "  ${BOLD}SUPER + Q${NC}          Ghostty Terminal"
    echo -e "  ${BOLD}SUPER + E${NC}          Thunar File Manager"
    echo -e "  ${BOLD}SUPER + B${NC}          Browser (Firefox / Brave)"
    echo -e "  ${BOLD}SUPER + F4${NC}         Close Active Window"
    echo -e "  ${BOLD}SUPER + T${NC}          Toggle Window Floating"
    echo -e "  ${BOLD}SUPER + F${NC}          Toggle Fullscreen"
    echo -e "  ${BOLD}SUPER + ALT + N${NC}    Toggle Blue Light / Night Light Filter"
    echo -e "  ${BOLD}Print${NC}              Interactive Region Screenshot (grim + slurp)"
    echo -e "  ${BOLD}SUPER + SHIFT + R${NC}  Interactive Screen Recording (wf-recorder)"
    echo -e "  ${BOLD}SUPER + M${NC}          Exit Hyprland"
    echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"
    echo -e "\n${BOLD}To start your session:${NC}"
    echo -e "  Log in via your display manager (SDDM) selecting ${BOLD}Hyprland${NC}, or run ${BOLD}Hyprland${NC} / ${BOLD}start-hyprland${NC}.\n"
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
