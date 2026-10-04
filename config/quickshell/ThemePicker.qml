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

    onVisibleChanged: {
        if (visible) {
            readPresetProc.running = true
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

    // Escape key handler
    Item {
        anchors.fill: parent
        focus: themePickerWindow.visible
        Keys.onEscapePressed: themePickerWindow.close()
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

    // Main Card Modal Container
    Rectangle {
        anchors.centerIn: parent
        width: 600
        height: Math.min(680, mainLayout.implicitHeight + 40)
        radius: 16
        color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.95)
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
        border.width: 1

        scale: themePickerWindow.visible ? 1.0 : 0.94
        opacity: themePickerWindow.visible ? 1.0 : 0.0
        Behavior on scale {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 36
                    height: 36
                    radius: 8
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                    border.color: Theme.accent
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "󰸉"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: Theme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Theme & Palette Studio"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 14
                        color: Theme.fg0
                    }
                    Text {
                        text: "Choose a curated aesthetic preset or dynamic wallpaper extraction"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: Theme.silver
                    }
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: closeMouse.containsMouse ? Theme.bg2 : "transparent"
                    border.color: closeMouse.containsMouse ? Theme.bg3 : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
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

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.bg2
            }

            // Theme Cards ScrollView / List
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: [
                            {
                                id: "dynamic",
                                name: "Dynamic Wallpaper",
                                icon: "󰸉",
                                desc: "Material You generated from current wallpaper colors",
                                bg: Theme.bg1,
                                colors: [Theme.accent, Theme.primary, Theme.secondary, Theme.tertiary]
                            },
                            {
                                id: "blood_crimson",
                                name: "Blood Crimson",
                                icon: "🩸",
                                desc: "Katana ink black with razor-sharp blood crimson accents",
                                bg: "#08080c",
                                colors: ["#ff4d5a", "#ff7582", "#ff2a42", "#ff1744"]
                            },
                            {
                                id: "samurai_steel",
                                name: "Samurai Steel",
                                icon: "⚔️",
                                desc: "Crisp platinum monochrome with deep obsidian darks",
                                bg: "#0a0a0e",
                                colors: ["#f3f4f6", "#d1d5db", "#9ca3af", "#6b7280"]
                            },
                            {
                                id: "amoled",
                                name: "AMOLED Pitch Black",
                                icon: "🖤",
                                desc: "100% true pitch black with high contrast white & accents",
                                bg: "#000000",
                                colors: ["#ffffff", "#a1a1aa", "#71717a", "#ef4444"]
                            },
                            {
                                id: "tokyonight",
                                name: "Tokyo Night",
                                icon: "󰖔",
                                desc: "Deep indigo night with neon cyan & lavender accents",
                                bg: "#1a1b26",
                                colors: ["#7aa2f7", "#bb9af7", "#7dcfff", "#f7768e"]
                            },
                            {
                                id: "catppuccin",
                                name: "Catppuccin Mocha",
                                icon: "󰄛",
                                desc: "Soothing pastel dark palette with mauve & lavender",
                                bg: "#1e1e2e",
                                colors: ["#cba6f7", "#89b4fa", "#f5c2e7", "#a6e3a1"]
                            },
                            {
                                id: "gruvbox",
                                name: "Gruvbox Dark",
                                icon: "󰺞",
                                desc: "Warm retro contrast with bright orange & forest green",
                                bg: "#282828",
                                colors: ["#fe8019", "#fabd2f", "#b8bb26", "#83a598"]
                            },
                            {
                                id: "nord",
                                name: "Nord Arctic",
                                icon: "󰴸",
                                desc: "Arctic clean ice blue and cool slate tones",
                                bg: "#2e3440",
                                colors: ["#88c0d0", "#81a1c1", "#8fbcbb", "#bf616a"]
                            },
                            {
                                id: "cyberpunk",
                                name: "Cyberpunk Neon",
                                icon: "󰅒",
                                desc: "High octane neon pink, electric cyan & vivid yellow",
                                bg: "#08080c",
                                colors: ["#ff007f", "#00f0ff", "#ffe600", "#00ff9f"]
                            },
                            {
                                id: "rosepine",
                                name: "Rosé Pine",
                                icon: "󰐥",
                                desc: "All natural pine, warm gold, and vintage rose",
                                bg: "#191724",
                                colors: ["#ebbcba", "#f6c177", "#9ccfd8", "#eb6f92"]
                            }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            height: 62
                            radius: 10
                            readonly property bool isActive: themePickerWindow.activePreset === modelData.id
                            color: isActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12) : (cardMouse.containsMouse ? Theme.bg2 : Theme.bg1)
                            border.color: isActive ? Theme.accent : (cardMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Theme.bg2)
                            border.width: isActive ? 1.5 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                // Theme Icon badge
                                Rectangle {
                                    width: 38
                                    height: 38
                                    radius: 8
                                    color: modelData.bg
                                    border.color: Qt.rgba(255, 255, 255, 0.15)
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 16
                                        color: modelData.colors[0]
                                    }
                                }

                                // Title and Description
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            text: modelData.name
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.bold: true
                                            font.pixelSize: 12
                                            color: Theme.fg0
                                        }
                                        Rectangle {
                                            visible: parent.parent.parent.parent.isActive
                                            height: 16
                                            radius: 8
                                            width: activeText.implicitWidth + 10
                                            color: Theme.accent
                                            Text {
                                                id: activeText
                                                anchors.centerIn: parent
                                                text: "ACTIVE"
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: Theme.bg0
                                            }
                                        }
                                    }
                                    Text {
                                        text: modelData.desc
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        color: Theme.silver
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                // Color preview swatches
                                Row {
                                    spacing: 5
                                    Layout.alignment: Qt.AlignVCenter
                                    Repeater {
                                        model: modelData.colors
                                        Rectangle {
                                            width: 14
                                            height: 14
                                            radius: 7
                                            color: modelData
                                            border.color: Qt.rgba(255, 255, 255, 0.25)
                                            border.width: 1
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: themePickerWindow.selectTheme(modelData.id)
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.bg2
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰌌 Shortcut: ALT + T"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: Theme.silver
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    height: 32
                    Layout.preferredWidth: 80
                    radius: 6
                    color: cancelMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: Theme.bg3
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Theme.fg1
                    }
                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: themePickerWindow.close()
                    }
                }
            }
        }
    }
}
