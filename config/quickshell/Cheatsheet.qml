import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: cheatsheetWindow

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    signal requestClose()

    function close() {
        cheatsheetWindow.requestClose()
    }

    function resetView() {
        searchField.text = ""
        currentCategory = "all"
        focusTimer.restart()
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: searchField.forceActiveFocus()
    }

    onVisibleChanged: {
        if (visible) {
            resetView()
        }
    }

    property string currentCategory: "all"
    property string searchQuery: ""

    // Click outside backdrop to close
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        opacity: cheatsheetWindow.visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        MouseArea {
            anchors.fill: parent
            onClicked: cheatsheetWindow.close()
        }
    }


    // Complete Keybindings Database
    readonly property var allShortcuts: [
        // Applications & Launch
        { cat: "apps", icon: "󰞷", desc: "Terminal (Ghostty)", detail: "Launch primary tiled terminal", keys: ["SUPER", "Q"] },
        { cat: "apps", icon: "󰀻", desc: "App Launcher", detail: "Spotlight application search", keys: ["SUPER", "SPACE"] },
        { cat: "apps", icon: "󰀻", desc: "App Launcher (Alt)", detail: "Classic dmenu shortcut", keys: ["SUPER", "D"] },
        { cat: "apps", icon: "󰞷", desc: "Scratchpad Terminal", detail: "Seamless floating popup terminal", keys: ["SUPER", "`"] },
        { cat: "apps", icon: "󰞷", desc: "Scratchpad Terminal (Alt)", detail: "Secondary toggle bind", keys: ["SUPER", "U"] },
        { cat: "apps", icon: "󰈹", desc: "Firefox Browser", detail: "Launch default web browser", keys: ["SUPER", "B"] },
        { cat: "apps", icon: "󰊯", desc: "Brave Browser", detail: "Launch Brave browser", keys: ["SUPER", "SHIFT", "B"] },
        { cat: "apps", icon: "󰉋", desc: "File Manager (Thunar)", detail: "Open GUI file explorer", keys: ["SUPER", "E"] },

        // Theming & Rice
        { cat: "theme", icon: "󰸉", desc: "Wallpaper & Rice Menu", detail: "Wallpaper picker with full palette sync", keys: ["SUPER", "W"] },
        { cat: "theme", icon: "󰸉", desc: "Wallpaper Menu Only", detail: "Change wallpaper keeping active theme", keys: ["SUPER", "SHIFT", "W"] },
        { cat: "theme", icon: "󰏘", desc: "Theme Studio", detail: "Curated presets (Catppuccin, Tokyo, etc.)", keys: ["ALT", "T"] },
        { cat: "theme", icon: "󱂬", desc: "Window Overview / Exposé", detail: "Native Exposé window switcher", keys: ["SUPER", "TAB"] },
        { cat: "theme", icon: "󱂬", desc: "Window Overview (Alt)", detail: "Standard Alt-Tab window switcher", keys: ["ALT", "TAB"] },
        { cat: "theme", icon: "󰅍", desc: "Clipboard History", detail: "Search & paste clipboard history", keys: ["SUPER", "V"] },
        { cat: "theme", icon: "󰍡", desc: "Control Center / Dashboard", detail: "Slide-out widgets & notifications", keys: ["SUPER", "N"] },
        { cat: "theme", icon: "󰒓", desc: "Settings & Tuning Hub", detail: "Live rice physics & system monitor", keys: ["SUPER", ","] },
        { cat: "theme", icon: "󰌌", desc: "Shortcuts Cheatsheet", detail: "Toggle this keybindings guide", keys: ["SUPER", "/"] },

        // Window Management
        { cat: "windows", icon: "󰅙", desc: "Close Active Window", detail: "Kill currently focused client", keys: ["SUPER", "F4"] },
        { cat: "windows", icon: "󰘔", desc: "Toggle Floating", detail: "Toggle window between float and tile", keys: ["SUPER", "T"] },
        { cat: "windows", icon: "󰊓", desc: "Toggle Fullscreen", detail: "True fullscreen mode toggle", keys: ["SUPER", "F"] },
        { cat: "windows", icon: "󰘔", desc: "Toggle Pseudo-Tile", detail: "Retain window aspect in tile layout", keys: ["SUPER", "P"] },
        { cat: "windows", icon: "󰤉", desc: "Toggle Dwindle Split", detail: "Switch split orientation (V / H)", keys: ["SUPER", "J"] },
        { cat: "windows", icon: "󰁔", desc: "Focus Navigation", detail: "Move focus to adjacent window", keys: ["SUPER", "Arrows"] },
        { cat: "windows", icon: "󰁔", desc: "Focus Navigation (Vim)", detail: "Vim navigation (H = left, K = up)", keys: ["SUPER", "H / K"] },
        { cat: "windows", icon: "󰁞", desc: "Move Window Position", detail: "Move active window in layout", keys: ["SUPER", "SHIFT", "Arrows"] },
        { cat: "windows", icon: "󰁞", desc: "Move Window (Vim)", detail: "Move active window with Vim keys", keys: ["SUPER", "SHIFT", "H/J/K"] },
        { cat: "windows", icon: "󰩨", desc: "Resize Active Window", detail: "Grow/shrink window dimensions (±30px)", keys: ["SUPER", "ALT", "Arrows"] },
        { cat: "windows", icon: "󰍽", desc: "Move Floating Window", detail: "Drag window with mouse", keys: ["SUPER", "LMB Drag"] },
        { cat: "windows", icon: "󰍽", desc: "Resize Floating Window", detail: "Resize window with mouse", keys: ["SUPER", "RMB Drag"] },

        // Workspaces
        { cat: "workspaces", icon: "󰍹", desc: "Switch Workspace", detail: "Navigate directly to workspace 1 to 10", keys: ["SUPER", "1 .. 0"] },
        { cat: "workspaces", icon: "󰍹", desc: "Send Window to Workspace", detail: "Move active window to workspace 1..10", keys: ["SUPER", "SHIFT", "1 .. 0"] },
        { cat: "workspaces", icon: "󰓡", desc: "Special Workspace", detail: "Toggle hidden magic scratchpad", keys: ["SUPER", "S"] },
        { cat: "workspaces", icon: "󰓡", desc: "Move to Special Workspace", detail: "Move active window to special workspace", keys: ["SUPER", "CTRL", "S"] },
        { cat: "workspaces", icon: "󰍹", desc: "Cycle Workspaces", detail: "Scroll through workspaces with mouse", keys: ["SUPER", "Scroll"] },

        // System & Media
        { cat: "system", icon: "󰌾", desc: "Lock Screen", detail: "Lock session using hyprlock", keys: ["SUPER", "L"] },
        { cat: "system", icon: "󰐥", desc: "Power & Session Menu", detail: "Shutdown, reboot, logout modal", keys: ["SUPER", "X"] },
        { cat: "system", icon: "󰈆", desc: "Exit Hyprland", detail: "Quit compositor and return to tty/greeter", keys: ["SUPER", "M"] },
        { cat: "system", icon: "󰄀", desc: "Screenshot Region", detail: "Select region to capture (slurp+grim)", keys: ["Print"] },
        { cat: "system", icon: "󰄀", desc: "Screenshot Window", detail: "Capture active focused window", keys: ["SHIFT", "Print"] },
        { cat: "system", icon: "󰄀", desc: "Screenshot Window (Alt)", detail: "Capture active window shortcut", keys: ["SUPER", "Print"] },
        { cat: "system", icon: "󰕧", desc: "Screen Recording", detail: "Record selected area with audio", keys: ["SUPER", "SHIFT", "R"] },
        { cat: "system", icon: "󰖔", desc: "Blue Light Filter", detail: "Cycle Night Light (4500K -> 3500K -> 2700K)", keys: ["SUPER", "SHIFT", "N"] },
        { cat: "system", icon: "󰕾", desc: "Volume & Mute", detail: "Laptop audio keys (Raise, Lower, Mute)", keys: ["Volume Keys"] },
        { cat: "system", icon: "󰃠", desc: "Screen Brightness", detail: "Laptop display brightness keys", keys: ["Brightness Keys"] },
        { cat: "system", icon: "󰐊", desc: "Media Playback", detail: "Play, Pause, Next, Previous track", keys: ["Media Keys"] }
    ]

    // Filtered items computed property
    property var filteredShortcuts: {
        let q = searchQuery.trim().toLowerCase()
        let cat = currentCategory
        let res = []

        for (let i = 0; i < allShortcuts.length; i++) {
            let item = allShortcuts[i]
            if (cat !== "all" && item.cat !== cat) continue

            if (q.length > 0) {
                let match = item.desc.toLowerCase().indexOf(q) !== -1 ||
                            item.detail.toLowerCase().indexOf(q) !== -1 ||
                            item.keys.join(" ").toLowerCase().indexOf(q) !== -1
                if (!match) continue
            }
            res.push(item)
        }
        return res
    }

    // Main Card Modal Container (Sleek, Compact, Non-book-like)
    Rectangle {
        id: mainCard
        width: 480
        height: 620
        anchors.centerIn: parent
        radius: 12
        color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.98)
        border.color: Theme.accent
        border.width: 2
        clip: true

        opacity: cheatsheetWindow.visible ? 1.0 : 0.0
        scale: cheatsheetWindow.visible ? 1.0 : 0.96
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // Header Section: Title & Close Button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰌌"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: Theme.accent
                }

                Text {
                    text: "Shortcuts Cheatsheet"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.fg0
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    color: closeArea.containsMouse ? Theme.bg2 : "transparent"
                    border.color: closeArea.containsMouse ? Theme.bg3 : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: closeArea.containsMouse ? Theme.red : Theme.gray
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cheatsheetWindow.close()
                    }
                }
            }

            // Search Filter Bar
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 8
                color: Theme.bg1
                border.color: searchField.activeFocus ? Theme.accent : Theme.bg3
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "󰍉"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: searchField.activeFocus ? Theme.accent : Theme.gray
                    }

                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        color: Theme.fg0
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        selectByMouse: true
                        clip: true

                        Text {
                            text: "Search shortcuts..."
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: Theme.gray
                            visible: !searchField.text && !searchField.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        onTextChanged: {
                            cheatsheetWindow.searchQuery = text
                            if (shortcutList) shortcutList.currentIndex = 0
                        }

                        Keys.onDownPressed: {
                            if (shortcutList.count > 0) {
                                shortcutList.incrementCurrentIndex()
                                shortcutList.positionViewAtIndex(shortcutList.currentIndex, ListView.Contain)
                            }
                        }
                        Keys.onUpPressed: {
                            if (shortcutList.count > 0) {
                                shortcutList.decrementCurrentIndex()
                                shortcutList.positionViewAtIndex(shortcutList.currentIndex, ListView.Contain)
                            }
                        }
                        Keys.onTabPressed: {
                            let cats = ["all", "apps", "theme", "windows", "workspaces", "system"]
                            let idx = cats.indexOf(cheatsheetWindow.currentCategory)
                            cheatsheetWindow.currentCategory = cats[(idx + 1) % cats.length]
                        }
                        Keys.onBacktabPressed: {
                            let cats = ["all", "apps", "theme", "windows", "workspaces", "system"]
                            let idx = cats.indexOf(cheatsheetWindow.currentCategory)
                            cheatsheetWindow.currentCategory = cats[(idx - 1 + cats.length) % cats.length]
                        }

                        Keys.onEscapePressed: {
                            if (text.length > 0) {
                                text = ""
                            } else {
                                cheatsheetWindow.close()
                            }
                        }
                    }

                    Text {
                        text: "󰅖"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: clearArea.containsMouse ? Theme.fg0 : Theme.gray
                        visible: searchField.text.length > 0

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchField.text = ""
                                searchField.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            // Category Filter Pills
            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Repeater {
                    model: [
                        { id: "all", label: "All" },
                        { id: "apps", label: "Apps" },
                        { id: "theme", label: "Theme" },
                        { id: "windows", label: "Win" },
                        { id: "workspaces", label: "Work" },
                        { id: "system", label: "Sys" }
                    ]

                    Rectangle {
                        height: 24
                        Layout.fillWidth: true
                        radius: 6
                        color: cheatsheetWindow.currentCategory === modelData.id ? Theme.accent : Theme.bg1
                        border.color: cheatsheetWindow.currentCategory === modelData.id ? Theme.accent : Theme.bg2
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            font.bold: cheatsheetWindow.currentCategory === modelData.id
                            color: cheatsheetWindow.currentCategory === modelData.id ? Theme.bg0 : Theme.fg1
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cheatsheetWindow.currentCategory = modelData.id
                        }
                    }
                }
            }

            // Shortcuts List View (Compact Single-line)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: Theme.bg1
                border.color: Qt.rgba(Theme.bg3.r, Theme.bg3.g, Theme.bg3.b, 0.6)
                border.width: 1
                clip: true

                ListView {
                    id: shortcutList
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 2
                    model: cheatsheetWindow.filteredShortcuts
                    boundsBehavior: Flickable.StopAtBounds
                    highlightFollowsCurrentItem: true
                    currentIndex: 0

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                    }

                    // Empty State
                    Text {
                        anchors.centerIn: parent
                        text: "No shortcuts found"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Theme.gray
                        visible: shortcutList.count === 0
                    }

                    delegate: Rectangle {
                        width: shortcutList.width
                        height: 32
                        radius: 6
                        readonly property bool isSelected: shortcutList.currentIndex === index
                        color: isSelected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : (itemArea.containsMouse ? Theme.bg2 : "transparent")
                        border.color: isSelected ? Theme.accent : (itemArea.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : "transparent")
                        border.width: isSelected ? 1.5 : 1

                        MouseArea {
                            id: itemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: shortcutList.currentIndex = index
                            onClicked: shortcutList.currentIndex = index
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: modelData.icon
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                color: Theme.accent
                            }

                            Text {
                                text: modelData.desc
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.bold: parent.parent.isSelected
                                color: parent.parent.isSelected ? Theme.fg0 : (itemArea.containsMouse ? Theme.fg0 : Theme.fg1)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Key Badges Row
                            Row {
                                spacing: 3
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                Repeater {
                                    model: modelData.keys

                                    Rectangle {
                                        height: 20
                                        implicitWidth: keyText.implicitWidth + 8
                                        radius: 4
                                        color: parent.parent.parent.parent.isSelected ? Theme.bg1 : Theme.bg0
                                        border.color: parent.parent.parent.parent.isSelected ? Theme.accent : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                                        border.width: 1

                                        Text {
                                            id: keyText
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: Theme.accent
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Footer bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "↑ / ↓ navigate • TAB category"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    color: Theme.gray
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "ESC to close"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    color: Theme.gray
                }
            }
        }
    }
}

