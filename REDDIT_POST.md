# 🛸 Reddit (r/unixporn) Showcase Post Guide

When you are ready to post this rice on **r/unixporn**, here is everything formatted and ready to copy-paste.

---

## 📌 Suggested Post Titles
Choose one that matches your style:
- `[Hyprland] Pure Quickshell Desktop Environment with Dynamic Material You Theming (Native Lua Config)`
- `[Hyprland] Ditched Waybar and Rofi for a unified Quickshell DE + Dynamic Colors`
- `[Hyprland] Material You Minimalist Desktop — Native Lua, Quickshell & Ghostty`

---

## 🖼️ Media to Upload
Upload these images from `assets/screenshots/` directly to Reddit in this order:
1. `clean_desktop.png` — Hero shot (Clean wallpaper + Top Bar).
2. `dashboard_1.png` — Quickshell Control Center / System Dashboard.
3. `launcher_1.png` — Quickshell Spotlight App Launcher.
4. `overview_1.png` — Tiled windows & dynamic gradient borders.

---

## 💬 Mandatory Details Comment (Copy & Paste as Top-Level Comment)

```markdown
### [Hyprland] Pure Quickshell DE & Dynamic Material You Theming

Finally packaged my daily driver setup! It runs native Hyprland Lua, a unified Quickshell desktop environment replacing Waybar, Rofi, and SwayNC, and dynamic Material You palette generation.

- **OS**: Arch Linux
- **WM**: [Hyprland](https://hyprland.org/) (`0.56+` with native Lua configuration)
- **Shell / Bar / Dashboard**: [Quickshell](https://git.outfoxxed.me/outfoxxed/quickshell) (Qt6 / QML)
- **Color Engine**: [Matugen](https://github.com/InioX/matugen) (Dynamic Material You extracted from wallpaper)
- **Terminal**: [Ghostty](https://ghostty.org/)
- **Prompt**: [Starship](https://starship.rs/)
- **Fetch**: [Fastfetch](https://github.com/fastfetch-cli/fastfetch)
- **Font**: JetBrainsMono Nerd Font
- **Wallpaper Daemon**: `awww`
- **Dotfiles & Installer**: [GitHub Repository](https://github.com/YOUR_USERNAME/hyprland-rice)

### Key Features:
- **Unified Quickshell DE**: Completely custom Qt6 QML implementation featuring an animated top bar, spotlight launcher (`SUPER + Space`), full system dashboard (`SUPER + N`), integrated notification daemon, and live wallpaper picker (`SUPER + W`).
- **Dynamic Theming**: Matugen extracts tonal palettes from any wallpaper and live-updates Hyprland active border gradients, Quickshell UI accents, and Ghostty terminal colors without restarting.
- **One-Line Installer**: Includes automated `install.sh` (with automatic backups) and safe `uninstall.sh`.
```

---

## 🚀 Pre-Post Checklist
- [ ] Push repository to GitHub:
  ```bash
  cd ~/hyprland-rice
  git remote add origin https://github.com/YOUR_USERNAME/hyprland-rice.git
  git branch -M main
  git push -u origin main
  ```
- [ ] Update `YOUR_USERNAME` in `README.md` and the Reddit comment above.
- [ ] Upload images to Reddit and immediately reply with the details comment (r/unixporn automod removes posts without a details comment within 1 hour).
