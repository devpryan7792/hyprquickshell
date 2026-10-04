import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property bool dashboardVisible: false
    property bool launcherVisible: false
    property bool wallpaperPickerVisible: false
    property bool calendarVisible: false
    property bool sessionVisible: false
    property bool settingsVisible: false
    property bool overviewVisible: false
    property bool themePickerVisible: false
    property bool cheatsheetVisible: false

    function closeAll() {
        dashboardVisible = false
        launcherVisible = false
        wallpaperPickerVisible = false
        calendarVisible = false
        sessionVisible = false
        settingsVisible = false
        overviewVisible = false
        themePickerVisible = false
        cheatsheetVisible = false
    }

    function toggleCheatsheet() {
        if (cheatsheetVisible) {
            cheatsheetVisible = false
        } else {
            closeAll()
            cheatsheetVisible = true
        }
    }

    function toggleSettings() {
        if (settingsVisible) {
            settingsVisible = false
        } else {
            closeAll()
            settingsVisible = true
        }
    }

    function toggleOverview() {
        if (overviewVisible) {
            overviewVisible = false
        } else {
            closeAll()
            overviewVisible = true
        }
    }

    function toggleThemePicker() {
        if (themePickerVisible) {
            themePickerVisible = false
        } else {
            closeAll()
            themePickerVisible = true
        }
    }

    function toggleSession() {
        if (sessionVisible) {
            sessionVisible = false
        } else {
            closeAll()
            sessionVisible = true
        }
    }

    function toggleDashboard() {
        if (dashboardVisible) {
            dashboardVisible = false
        } else {
            closeAll()
            dashboardVisible = true
        }
    }

    function toggleLauncher() {
        if (launcherVisible && launcher.currentMode === "apps") {
            launcherVisible = false
        } else {
            closeAll()
            launcher.openApps()
            launcherVisible = true
        }
    }

    function openLauncherClip() {
        if (launcherVisible && launcher.currentMode === "clip") {
            launcherVisible = false
        } else {
            closeAll()
            launcher.openClip()
            launcherVisible = true
        }
    }

    function toggleWallpaperPicker(wallOnly) {
        let isWallOnly = (wallOnly === true)
        if (wallpaperPickerVisible && wallpaperPicker.wallOnlyMode === isWallOnly) {
            wallpaperPickerVisible = false
        } else {
            closeAll()
            wallpaperPicker.wallOnlyMode = isWallOnly
            wallpaperPickerVisible = true
        }
    }

    function toggleCalendar() {
        if (calendarVisible) {
            calendarVisible = false
        } else {
            closeAll()
            calendarVisible = true
        }
    }

    // IPC Targets callable via: quickshell ipc call <target> <function>
    IpcHandler {
        target: "dashboard"
        function toggle() { root.toggleDashboard() }
    }

    IpcHandler {
        target: "launcher"
        function toggle() { root.toggleLauncher() }
        function clip() { root.openLauncherClip() }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle() { root.toggleWallpaperPicker(false) }
        function wallOnly() { root.toggleWallpaperPicker(true) }
    }

    IpcHandler {
        target: "calendar"
        function toggle() { root.toggleCalendar() }
    }

    IpcHandler {
        target: "session"
        function toggle() { root.toggleSession() }
    }

    IpcHandler {
        target: "settings"
        function toggle() { root.toggleSettings() }
    }

    IpcHandler {
        target: "overview"
        function toggle() { root.toggleOverview() }
    }

    IpcHandler {
        target: "theme_picker"
        function toggle() { root.toggleThemePicker() }
    }

    IpcHandler {
        target: "cheatsheet"
        function toggle() { root.toggleCheatsheet() }
    }

    IpcHandler {
        target: "theme"
        function reload() { Theme.reload() }
    }

    // Top Bar (Always visible)
    Bar {
        id: topBar
        onDashboardToggleRequested: root.toggleDashboard()
        onLauncherToggleRequested: root.toggleLauncher()
        onWallpaperToggleRequested: root.toggleWallpaperPicker()
        onCalendarToggleRequested: root.toggleCalendar()
    }

    // Dashboard Side Panel (Slide-out)
    Dashboard {
        id: dashboard
        visible: root.dashboardVisible
        onRequestClose: root.dashboardVisible = false
    }

    // App Launcher & Clipboard Modal
    Launcher {
        id: launcher
        visible: root.launcherVisible
        onRequestClose: root.launcherVisible = false
    }

    // Wallpaper & Palette Picker Modal
    WallpaperPicker {
        id: wallpaperPicker
        visible: root.wallpaperPickerVisible
        onRequestClose: root.wallpaperPickerVisible = false
    }

    // Interactive Calendar Dropdown Modal
    CalendarDropdown {
        id: calendarDropdown
        visible: root.calendarVisible
        onRequestClose: root.calendarVisible = false
    }

    // Native Session & Power Menu Modal (wlogout replacement)
    SessionMenu {
        id: sessionMenu
        visible: root.sessionVisible
        onRequestClose: root.sessionVisible = false
    }

    // Live Rice Settings Hub Modal
    SettingsHub {
        id: settingsHub
        visible: root.settingsVisible
        onRequestClose: root.settingsVisible = false
    }

    // Native Window Overview / Exposé Modal
    Overview {
        id: overview
        visible: root.overviewVisible
        onRequestClose: root.overviewVisible = false
    }

    // Curated Theme Preset Picker Modal (ALT+T)
    ThemePicker {
        id: themePicker
        visible: root.themePickerVisible
        onRequestClose: root.themePickerVisible = false
    }

    // Keybindings Cheatsheet Modal (SUPER+/)
    Cheatsheet {
        id: cheatsheet
        visible: root.cheatsheetVisible
        onRequestClose: root.cheatsheetVisible = false
    }

    // IPC handler for notifications
    IpcHandler {
        target: "notifications"
        function toggleDnd() { NotificationManager.toggleDnd() }
        function clear() { NotificationManager.clearAll() }
    }

    // Floating Notification Popups (Toast banners)
    NotificationPopup {
        id: notificationPopup
    }
}
