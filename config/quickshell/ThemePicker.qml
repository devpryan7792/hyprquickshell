import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: themePickerWindow

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
        themePickerWindow.requestClose()
    }

    property string activePreset: "dynamic"

    // Process to read current preset
    Process {
        id: readPresetProc
        command: ["cat", Quickshell.env("HOME") + "/.cache/hyprdots-preset"]
        stdout: SplitParser {
            onRead: data => {
                let p = data.trim()
                if (p.length > 0) {
                    themePickerWindow.activePreset = p
                }
            }
        }
    }

    // Process to apply preset
    Process {
        id: applyProc
        property var cmd: []
        command: cmd
    }

    function selectTheme(themeId) {
        themePickerWindow.activePreset = themeId
        themePickerWindow.close()
        let home = Quickshell.env("HOME")
        if (themeId === "dynamic") {
            applyProc.command = [home + "/.config/hypr/scripts/launch-app.sh", home + "/.config/hypr/scripts/theme-switcher.sh --dynamic"]
        } else {
            applyProc.command = [home + "/.config/hypr/scripts/launch-app.sh", home + "/.config/hypr/scripts/theme-switcher.sh --preset " + themeId]
        }
        applyProc.running = true
    }

    onVisibleChanged: {
        if (visible) {
            readPresetProc.running = true
            Qt.callLater(() => {
                for (let i = 0; i < themeList.model.length; i++) {
                    if (themeList.model[i].id === activePreset) {
                        themeList.currentIndex = i
                        break
                    }
                }
                themeList.forceActiveFocus()
            })
        }
    }

    // Dimmed backdrop (click to close)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        opacity: themePickerWindow.visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: themePickerWindow.close()
        }
    }

    // Main Card Modal Container (Sleek, Compact, Non-book-like)
    Rectangle {
        id: mainCard
        anchors.centerIn: parent
        width: 440
        height: 680
        radius: 12
        color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.98)
        border.color: Theme.accent
        border.width: 2
        clip: true

        scale: themePickerWindow.visible ? 1.0 : 0.96
        opacity: themePickerWindow.visible ? 1.0 : 0.0
        Behavior on scale {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // Header Row: Compact Title & Close
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰏘"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: Theme.accent
                }

                Text {
                    text: "Theme Presets"
                    font.family: "JetBrainsMono Nerd Font"
                    font.bold: true
                    font.pixelSize: 13
                    color: Theme.fg0
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    color: closeMouse.containsMouse ? Theme.bg2 : "transparent"
                    border.color: closeMouse.containsMouse ? Theme.bg3 : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: closeMouse.containsMouse ? Theme.red : Theme.silver
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: themePickerWindow.close()
                    }
                }
            }

            // Theme Cards ScrollView / List (Compact Single-line)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: Theme.bg1
                border.color: Qt.rgba(Theme.bg3.r, Theme.bg3.g, Theme.bg3.b, 0.6)
                border.width: 1
                clip: true

                ListView {
                    id: themeList
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    focus: true
                    highlightFollowsCurrentItem: true

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                    }

                    Keys.onDownPressed: themeList.incrementCurrentIndex()
                    Keys.onUpPressed: themeList.decrementCurrentIndex()
                    Keys.onReturnPressed: {
                        if (currentIndex >= 0 && currentIndex < model.length) {
                            themePickerWindow.selectTheme(model[currentIndex].id)
                        }
                    }
                    Keys.onEnterPressed: {
                        if (currentIndex >= 0 && currentIndex < model.length) {
                            themePickerWindow.selectTheme(model[currentIndex].id)
                        }
                    }
                    Keys.onEscapePressed: themePickerWindow.close()

                    model: [
                        {
                            id: "dynamic",
                            name: "Dynamic Wallpaper",
                            icon: "󰸉",
                            bg: Theme.bg1,
                            colors: [Theme.accent, Theme.primary, Theme.secondary, Theme.tertiary]
                        },
                        {
                            id: "blood_crimson",
                            name: "Blood Crimson",
                            icon: "🩸",
                            bg: "#08080c",
                            colors: ["#ff4d5a", "#ff7582", "#ff2a42", "#ff1744"]
                        },
                        {
                            id: "samurai_steel",
                            name: "Samurai Steel",
                            icon: "⚔️",
                            bg: "#0a0a0e",
                            colors: ["#f3f4f6", "#d1d5db", "#9ca3af", "#6b7280"]
                        },
                        {
                            id: "amoled",
                            name: "AMOLED Pitch Black",
                            icon: "🖤",
                            bg: "#000000",
                            colors: ["#ffffff", "#a1a1aa", "#71717a", "#ef4444"]
                        },
                        {
                            id: "tokyonight",
                            name: "Tokyo Night",
                            icon: "󰖔",
                            bg: "#1a1b26",
                            colors: ["#7aa2f7", "#bb9af7", "#7dcfff", "#f7768e"]
                        },
                        {
                            id: "catppuccin",
                            name: "Catppuccin Mocha",
                            icon: "󰄛",
                            bg: "#1e1e2e",
                            colors: ["#cba6f7", "#89b4fa", "#f5c2e7", "#a6e3a1"]
                        },
                        {
                            id: "gruvbox",
                            name: "Gruvbox Dark",
                            icon: "󰺞",
                            bg: "#282828",
                            colors: ["#fe8019", "#fabd2f", "#b8bb26", "#83a598"]
                        },
                        {
                            id: "nord",
                            name: "Nord Arctic",
                            icon: "󰴸",
                            bg: "#2e3440",
                            colors: ["#88c0d0", "#81a1c1", "#8fbcbb", "#bf616a"]
                        },
                        {
                            id: "cyberpunk",
                            name: "Cyberpunk Neon",
                            icon: "󰅒",
                            bg: "#08080c",
                            colors: ["#ff007f", "#00f0ff", "#ffe600", "#00ff9f"]
                        },
                        {
                            id: "rosepine",
                            name: "Rosé Pine",
                            icon: "󰐥",
                            bg: "#191724",
                            colors: ["#ebbcba", "#f6c177", "#9ccfd8", "#eb6f92"]
                        }
                    ]

                    delegate: Rectangle {
                        width: themeList.width
                        height: 36
                        radius: 6
                        readonly property bool isActive: themePickerWindow.activePreset === modelData.id
                        readonly property bool isSelected: themeList.currentIndex === index
                        color: isSelected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : (isActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12) : (cardMouse.containsMouse ? Theme.bg2 : "transparent"))
                        border.color: isSelected ? Theme.accent : (isActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5) : (cardMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : "transparent"))
                        border.width: isSelected || isActive ? 1.5 : 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Text {
                                text: modelData.icon
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: modelData.colors[0]
                            }

                            Text {
                                text: modelData.name
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: parent.parent.isSelected || parent.parent.isActive
                                font.pixelSize: 11
                                color: parent.parent.isSelected ? Theme.fg0 : (parent.parent.isActive ? Theme.accent : (cardMouse.containsMouse ? Theme.fg0 : Theme.fg1))
                                Layout.fillWidth: true
                            }

                            // Active check badge
                            Text {
                                visible: parent.parent.isActive
                                text: "󰄬"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.accent
                            }

                            // Color preview swatches (8px dots)
                            Row {
                                spacing: 4
                                Layout.alignment: Qt.AlignVCenter
                                Repeater {
                                    model: modelData.colors
                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: modelData
                                        border.color: Qt.rgba(255, 255, 255, 0.2)
                                        border.width: 0.5
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: themeList.currentIndex = index
                            onClicked: themePickerWindow.selectTheme(modelData.id)
                        }
                    }
                }
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "↑ / ↓ to navigate • ENTER to apply"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    color: Theme.silver
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "ESC to close"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    color: Theme.silver
                }
            }
        }
    }
}
