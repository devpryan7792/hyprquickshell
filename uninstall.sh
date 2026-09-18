#!/usr/bin/env bash
# =============================================================================
# Hyprland Rice — Complete Uninstaller & Backup Restoration
# =============================================================================

set -e

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

prompt_confirm() {
    local message="$1"
    local default="${2:-N}"
    local prompt="[y/N]"
    [ "$default" = "Y" ] && prompt="[Y/n]"

    read -rp "$message $prompt " response
    response="${response:-$default}"
    [[ "$response" =~ ^[Yy]$ ]]
}

echo -e "\n${RED}${BOLD}================================================================${NC}"
echo -e "${RED}${BOLD}             Hyprland Rice Uninstaller & Restore                 ${NC}"
echo -e "${RED}${BOLD}================================================================${NC}\n"

if ! prompt_confirm "Are you sure you want to uninstall the Hyprland rice configurations?" "N"; then
    log_info "Uninstallation aborted."
    exit 0
fi

LAST_BACKUP_FILE="$HOME/.config/hyprland-rice-last-backup"
RESTORED=false

if [ -f "$LAST_BACKUP_FILE" ]; then
    BACKUP_DIR=$(cat "$LAST_BACKUP_FILE")
    if [ -d "$BACKUP_DIR" ]; then
        log_step "Backup Detected"
        log_info "Found previous configuration backup at:"
        echo -e "  ${CYAN}$BACKUP_DIR${NC}"
        
        if prompt_confirm "Would you like to restore this backup now?" "Y"; then
            log_step "Restoring Previous Configurations"

            # Remove current rice configs
            rm -rf "$HOME/.config/hypr"
            rm -rf "$HOME/.config/quickshell"
            rm -rf "$HOME/.config/matugen"
            rm -rf "$HOME/.config/ghostty"
            rm -rf "$HOME/.config/fastfetch"
            rm -f  "$HOME/.config/starship.toml"

            # Copy back from backup
            for item in "$BACKUP_DIR"/*; do
                if [ -e "$item" ]; then
                    name=$(basename "$item")
                    if [[ "$name" == .* ]]; then
                        # Home dotfiles (.zshrc, .bashrc)
                        log_info "Restoring ~/$name..."
                        cp -rf "$item" "$HOME/"
                    else
                        # Config directories
                        log_info "Restoring ~/.config/$name..."
                        cp -rf "$item" "$HOME/.config/"
                    fi
                fi
            done

            RESTORED=true
            log_ok "Previous configurations restored successfully."
            rm -f "$LAST_BACKUP_FILE"
        fi
    fi
fi

if [ "$RESTORED" = false ]; then
    log_step "Removing Rice Configurations"
    
    if prompt_confirm "Remove ~/.config/{hypr, quickshell, matugen, ghostty, fastfetch, starship.toml}?" "Y"; then
        rm -rf "$HOME/.config/hypr"
        rm -rf "$HOME/.config/quickshell"
        rm -rf "$HOME/.config/matugen"
        rm -rf "$HOME/.config/ghostty"
        rm -rf "$HOME/.config/fastfetch"
        rm -f  "$HOME/.config/starship.toml"
        log_ok "Removed rice configuration directories."
    fi
fi

# Clean up runtime caches
log_step "Cleaning Caches"
rm -f "$HOME/.cache/hyprdots-wallpaper"
rm -f "$HOME/.cache/hyprdots-theme-scheme"
rm -f "$HOME/.cache/quickshell-launcher-frecency.json"
rm -f "/tmp/bluelight_state" 2>/dev/null || true
log_ok "Caches cleaned."

echo -e "\n${GREEN}${BOLD}✔ Uninstallation complete.${NC}"
log_info "Installed packages (hyprland, quickshell, etc.) have been preserved so dependencies are not broken."
log_info "To remove packages completely, use: sudo pacman -Rns quickshell-git matugen-bin awww (or your chosen packages).\n"
