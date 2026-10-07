# 🛸 Reddit (r/unixporn) Showcase Post Guide

Everything formatted and ready to copy-paste when posting this rice on **r/unixporn**.

---

## 📌 Suggested Post Titles
Choose one that matches your style:
- `[Hyprland] Pure Quickshell Desktop Environment + Dynamic Material You Theming (Native Lua Config)`
- `[Hyprland] Replaced Waybar, Rofi & SwayNC with a unified Quickshell DE + Dynamic Wallpaper Colors`
- `[Hyprland] Berserk Aesthetic — Native Lua, Quickshell Desktop & Ghostty`

---

## 🖼️ Media to Upload to Reddit
Upload these images from `assets/screenshots/` (and optional showcase GIF) directly to Reddit in this order:
1. `overview_1.png` — Hero shot: Tiled Ghostty with Fastfetch + Neovim with dynamic border gradients & workspace pills.
2. `clean_desktop.png` — Minimalist clean wallpaper + Quickshell top bar.
3. `dashboard_1.png` — Quickshell Control Center & System Dashboard.
4. `launcher_1.png` — Quickshell Spotlight App Launcher.
5. `wallpaper_picker.png` — Quickshell Wallpaper Studio & Dynamic Palette Switcher.
6. `cheatsheet_1.png` — Keyboard Shortcuts Cheatsheet modal.

> *(Optional: Upload `assets/showcase.gif` as video / GIF showcase)*

---

## 💬 Mandatory Details Comment (Copy & Paste as Top-Level Comment)

```markdown
### [Hyprland] Pure Quickshell Desktop & Dynamic Material You Theming

Packaged my daily driver setup! Built around native Hyprland Lua, a unified Quickshell desktop environment replacing Waybar, Rofi, and SwayNC, and dynamic Material You palette generation.

- **OS**: [Arch Linux](https://archlinux.org/)
- **WM**: [Hyprland](https://hyprland.org/) (`0.56+` with native Lua configuration)
- **Shell / Bar / Dashboard**: [Quickshell](https://git.outfoxxed.me/quickshell) (Qt6 / QML)
- **Color Engine**: [Matugen](https://github.com/InioX/matugen) (Dynamic Material You extracted from wallpaper)
- **Terminal**: [Ghostty](https://ghostty.org/)
- **Editor**: Neovim
- **Prompt**: [Starship](https://starship.rs/)
- **Fetch**: [Fastfetch](https://github.com/fastfetch-cli/fastfetch)
- **Font**: JetBrainsMono Nerd Font
- **Wallpaper Daemon**: `awww`
- **Dotfiles & Turnkey Installer**: [GitHub Repository](https://github.com/devpryan7792/hyprquickdots)

### Key Features:
- **Unified Quickshell DE**: Custom Qt6 QML desktop including an animated top bar, spotlight launcher (`SUPER + Space`), control center dashboard (`SUPER + N`), keybindings cheatsheet (`SUPER + /`), and wallpaper studio (`SUPER + W`).
- **Dynamic Theming**: Matugen extracts tonal palettes from any wallpaper and instantly updates Hyprland active border gradients, Quickshell UI accents, and Ghostty terminal colors without restarting.
- **Turnkey Setup**: Includes automated `install.sh` (supporting live symlink mode or standalone copy mode with automatic backups) and safe `uninstall.sh`.
```

---

## 🚀 Pre-Post Checklist
- [x] Tested dotfiles with live symlinks in `~/.config`.
- [x] Generated media assets without Antigravity IDE in view.
- [x] Push repository to GitHub (`devpryan7792/hyprquickdots`).
- [ ] Create post on r/unixporn with the images above.
- [ ] Immediately paste the details comment above as the top-level comment (r/unixporn automod removes posts without a details comment within 1 hour).
