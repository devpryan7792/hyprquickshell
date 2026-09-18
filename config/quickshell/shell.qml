import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property bool dashboardVisible: false
    property bool launcherVisible: false
    property bool wallpaperPickerVisible: false
    property bool calendarVisible: false

    function closeAll() {
        dashboardVisible = false
        launcherVisible = false
        wallpaperPickerVisible = false
        calendarVisible = false
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

    function toggleWallpaperPicker() {
        if (wallpaperPickerVisible) {
            wallpaperPickerVisible = false
        } else {
            closeAll()
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
        function toggle() { root.toggleWallpaperPicker() }
    }

    IpcHandler {
        target: "calendar"
        function toggle() { root.toggleCalendar() }
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
