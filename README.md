<div align="center">

# ✦ Hyprland Material You Rice ✦
### Native Hyprland Lua  •  Pure Quickshell Desktop  •  Dynamic Palette Generation

[![Arch Linux](https://img.shields.io/badge/OS-Arch_Linux-1793d1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org)
[![Hyprland](https://img.shields.io/badge/WM-Hyprland_Lua-00c853?style=for-the-badge&logo=hyprland&logoColor=white)](https://hyprland.org)
[![Quickshell](https://img.shields.io/badge/Shell-Quickshell_Qt6-673ab7?style=for-the-badge&logo=qt&logoColor=white)](https://git.outfoxxed.me/outfoxxed/quickshell)
[![Ghostty](https://img.shields.io/badge/Terminal-Ghostty-ff5722?style=for-the-badge&logo=ghost&logoColor=white)](https://ghostty.org)
[![Matugen](https://img.shields.io/badge/Colors-Matugen_Material_You-e91e63?style=for-the-badge&logo=material-design&logoColor=white)](https://github.com/InioX/matugen)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

*A clean, GPU-accelerated Wayland desktop crafted around native Hyprland Lua, a unified Quickshell interface (replacing Waybar, Rofi, and SwayNC), and wallpaper-reactive Material You color generation.*

---

</div>

## 📸 Showcase Gallery

<div align="center">

### Clean Desktop View
![Clean Desktop](assets/screenshots/clean_desktop.png)

### Quickshell Spotlight App Launcher (`SUPER + SPACE`)
![App Launcher](assets/screenshots/launcher_1.png)

### Quickshell Control Center & System Dashboard (`SUPER + N`)
![Control Center Dashboard](assets/screenshots/dashboard_1.png)

### Tiled Workspaces & Dynamic Window Borders
![Desktop Overview](assets/screenshots/overview_1.png)

</div>

---

## 🎨 System Specs & Details

| Component | Software / Details |
| :--- | :--- |
| **OS** | [Arch Linux](https://archlinux.org/) |
| **Compositor** | [Hyprland](https://hyprland.org/) (`0.56+` with native Lua configuration) |
| **Desktop Shell** | [Quickshell](https://git.outfoxxed.me/outfoxxed/quickshell) (Qt6 / QML native Top Bar, Dashboard, Launcher & Notifications) |
| **Color Engine** | [Matugen](https://github.com/InioX/matugen) (Extracts Material You palettes from wallpaper) |
| **Wallpaper Daemon** | [awww](https://github.com/danielfullmer/awww) (Smooth GPU transitions) |
| **Terminal** | [Ghostty](https://ghostty.org/) (Native blur, padding, Material You theme integration) |
| **Shell** | `zsh` + `fzf-tab` (IntelliSense popups) + `zoxide` + `fastfetch` |
| **Prompt** | [Starship](https://starship.rs/) (Minimalist Material You dark theme) |
| **Font** | `JetBrainsMono Nerd Font` |
| **File Manager** | `thunar` |
| **Blue Light Filter** | `hyprsunset` (`SUPER + ALT + N` toggle) |
| **Screenshot Tool** | `grim` + `slurp` + `wl-clipboard` |
| **Screen Recording**| `wf-recorder` (`SUPER + SHIFT + R`) |

---

## ✨ Features

- **🚀 Native Hyprland Lua**: Written entirely in Lua (`hyprland.lua`, `lua/*.lua`), eliminating legacy config quirks and allowing modular code organization.
- **💎 Pure Quickshell Desktop Environment**:
  - **Unified Architecture**: Replaces Waybar, Rofi, Dunst/SwayNC, and external wallpaper switchers with a single, ultra-fast Qt6 QML daemon.
  - **Dynamic Top Bar**: Displays animated workspace pills, active window title, system indicators, and an interactive calendar dropdown.
  - **Spotlight App Launcher**: Instant fuzzy application search with frecency scoring, icon resolution, and clipboard history (`SUPER + V`).
  - **Full Control Center**: Network/Bluetooth toggles, Night Light controls, hardware telemetry (CPU, RAM, GPU, top processes), media controls, and volume/brightness sliders.
  - **Wallpaper Picker**: Visual wallpaper selector with live preview and smooth wipe transitions (`SUPER + W`).
- **🌈 Adaptive Material You Theming**:
  - Switching wallpapers dynamically extracts tonal color palettes with Matugen.
  - Instantly updates Hyprland window border gradients, Quickshell accent colors, and Ghostty terminal color schemes on the fly.
- **⚡ Supercharged Shell**:
  - Zsh featuring `fzf-tab` for interactive floating tab completion with live previews.
  - Fast directory jumping with `zoxide`.
  - Modern CLI aliases (`eza` for `ls`, `bat` for `cat`, `fastfetch`).

---

## ⌨️ Keybindings Cheat Sheet

| Keybinding | Action |
| :--- | :--- |
| `SUPER + SPACE` | Toggle Spotlight Application Launcher |
| `SUPER + N` | Toggle Control Center / Dashboard Side Panel |
| `SUPER + W` | Toggle Wallpaper Picker & Dynamic Theme Switcher |
| `SUPER + V` | Open Clipboard History |
| `SUPER + Q` | Launch Ghostty Terminal |
| `SUPER + E` | Open Thunar File Manager |
| `SUPER + B` | Launch Default Web Browser |
| `SUPER + F4` | Close / Kill Active Window |
| `SUPER + T` | Toggle Window Floating |
| `SUPER + F` | Toggle Fullscreen |
| `SUPER + S` | Toggle Scratchpad / Special Workspace |
| `SUPER + [1-9]` | Switch to Workspace 1-9 |
| `SUPER + SHIFT + [1-9]` | Move Window to Workspace 1-9 |
| `SUPER + ALT + Arrows/Vim` | Resize Active Window |
| `SUPER + ALT + N` | Cycle Blue Light / Night Light (Off → 4500K → 3500K → 2700K) |
| `Print` | Interactive Region Screenshot (copies to clipboard & saves to `~/Pictures/shots`) |
| `SUPER + SHIFT + R` | Start / Stop Region Screen Recording (`~/Videos/recordings`) |
| `SUPER + M` | Exit Hyprland Compositor |

---

## 📦 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/hyprland-rice.git ~/hyprland-rice
cd ~/hyprland-rice
```

### 2. Run the Installer
```bash
chmod +x install.sh
./install.sh
```

> **Options:**
> - `./install.sh -y` — Non-interactive unattended installation.
> - `./install.sh -s` — Symlinks dotfiles instead of copying (ideal for active development).

The installer will:
1. Verify system environment and detect your AUR helper (`yay` or `paru`).
2. Install all required official and AUR packages.
3. Automatically back up existing configs to `~/.config/hyprland-rice-backup-<timestamp>`.
4. Deploy configurations for Hyprland, Quickshell, Matugen, Ghostty, Fastfetch, and Zsh.
5. Clone required Zsh plugins (`fzf-tab`, autosuggestions, syntax-highlighting).
6. Copy curated wallpapers and run initial palette extraction.

---

## 🔄 Uninstallation

To cleanly remove the rice configurations and restore your previous desktop setup:
```bash
cd ~/hyprland-rice
./uninstall.sh
```
If an installation backup exists, `uninstall.sh` will prompt to automatically restore your previous dotfiles.

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.
