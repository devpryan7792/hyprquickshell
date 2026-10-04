import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: settingsWindow

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
        settingsWindow.requestClose()
    }

    // Live tuning state (initialized with rice defaults)
    property int gapsIn: 3
    property int gapsOut: 6
    property int rounding: 6
    property int borderSize: 2
    property string animProfile: "smooth"
    property string activeSurface: "material"

    // Non-blocking process execution
    Process {
        id: execProc
        property var cmd: []
        command: cmd
    }

    function runDetached(cmdStr) {
        execProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/launch-app.sh", cmdStr]
        execProc.running = true
    }

    // 30ms debounced live Hyprland evaluator
    Timer {
        id: liveEvalTimer
        interval: 30
        repeat: false
        onTriggered: {
            let evalCode = "hl.config({ general = { gaps_in = " + settingsWindow.gapsIn +
                           ", gaps_out = " + settingsWindow.gapsOut +
                           ", border_size = " + settingsWindow.borderSize +
                           " }, decoration = { rounding = " + settingsWindow.rounding + " } })"
            runDetached("hyprctl eval \"" + evalCode + "\"")
        }
    }

    function setAnimProfile(name) {
        settingsWindow.animProfile = name
        let cmd = ""
        if (name === "instant") {
            cmd = "hyprctl eval \"hl.config({ animations = { enabled = false } })\""
        } else if (name === "snappy") {
            cmd = "hyprctl eval \"hl.config({ animations = { enabled = true } }); hl.animation({ leaf = 'global', speed = 3, bezier = 'quick' }); hl.animation({ leaf = 'windows', speed = 3, bezier = 'easeOutQuint' })\""
        } else if (name === "smooth") {
            cmd = "hyprctl eval \"hl.config({ animations = { enabled = true } }); hl.animation({ leaf = 'global', speed = 6, bezier = 'default' }); hl.animation({ leaf = 'windows', speed = 4.8, spring = 'easy' })\""
        } else if (name === "float") {
            cmd = "hyprctl eval \"hl.config({ animations = { enabled = true } }); hl.animation({ leaf = 'global', speed = 10, bezier = 'default' }); hl.animation({ leaf = 'windows', speed = 8, spring = 'easy' })\""
        }
        if (cmd.length > 0) {
            runDetached(cmd)
        }
    }

    function resetDefaults() {
        settingsWindow.gapsIn = 3
        settingsWindow.gapsOut = 6
        settingsWindow.rounding = 6
        settingsWindow.borderSize = 2
        setAnimProfile("smooth")
        liveEvalTimer.restart()
    }

    // Esc key handler
    Item {
        anchors.fill: parent
        focus: settingsWindow.visible
        Keys.onEscapePressed: settingsWindow.close()
    }

    // Dimmed backdrop (click to close)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        opacity: settingsWindow.visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: settingsWindow.close()
        }
    }

    // Main Studio Card Container
    Rectangle {
        anchors.centerIn: parent
        width: 520
        height: cardLayout.implicitHeight + 40
        radius: 16
        color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.95)
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
        border.width: 1

        scale: settingsWindow.visible ? 1.0 : 0.94
        opacity: settingsWindow.visible ? 1.0 : 0.0
        Behavior on scale {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: cardLayout
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 20
            spacing: 16

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
                        text: "󰒓"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: Theme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Rice Live Studio"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 14
                        color: Theme.fg0
                    }
                    Text {
                        text: "Real-time desktop aesthetic & physics tuning"
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
                        onClicked: settingsWindow.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.bg2
            }

            // SLIDERS SECTION
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                // Window Gaps In
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: "Inner Gaps"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Theme.fg1
                        Layout.preferredWidth: 100
                    }
                    Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: 20
                        stepSize: 1
                        value: settingsWindow.gapsIn
                        onMoved: {
                            settingsWindow.gapsIn = Math.round(value)
                            liveEvalTimer.restart()
                        }
                    }
                    Text {
                        text: settingsWindow.gapsIn + " px"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.accent
                        Layout.preferredWidth: 44
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // Window Gaps Out
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: "Outer Gaps"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Theme.fg1
                        Layout.preferredWidth: 100
                    }
                    Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: 30
                        stepSize: 1
                        value: settingsWindow.gapsOut
                        onMoved: {
                            settingsWindow.gapsOut = Math.round(value)
                            liveEvalTimer.restart()
                        }
                    }
                    Text {
                        text: settingsWindow.gapsOut + " px"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.accent
                        Layout.preferredWidth: 44
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // Corner Radius
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: "Corner Radius"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Theme.fg1
                        Layout.preferredWidth: 100
                    }
                    Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: 24
                        stepSize: 1
                        value: settingsWindow.rounding
                        onMoved: {
                            settingsWindow.rounding = Math.round(value)
                            liveEvalTimer.restart()
                        }
                    }
                    Text {
                        text: settingsWindow.rounding + " px"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.accent
                        Layout.preferredWidth: 44
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // Border Width
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: "Border Width"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Theme.fg1
                        Layout.preferredWidth: 100
                    }
                    Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: 6
                        stepSize: 1
                        value: settingsWindow.borderSize
                        onMoved: {
                            settingsWindow.borderSize = Math.round(value)
                            liveEvalTimer.restart()
                        }
                    }
                    Text {
                        text: settingsWindow.borderSize + " px"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.accent
                        Layout.preferredWidth: 44
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.bg2
            }

            // ANIMATION PROFILES
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Animation Physics Profile"
                    font.family: "JetBrainsMono Nerd Font"
                    font.bold: true
                    font.pixelSize: 11
                    color: Theme.silver
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "instant", label: "Instant", icon: "󰓅", desc: "0ms / Max FPS" },
                            { id: "snappy",  label: "Snappy",  icon: "󰁨", desc: "Fast & Sharp" },
                            { id: "smooth",  label: "Smooth",  icon: "󰓅", desc: "Default Spring" },
                            { id: "float",   label: "Float",   icon: "󰾕", desc: "Soft & Airy" }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            height: 38
                            radius: 8
                            readonly property bool isSelected: settingsWindow.animProfile === modelData.id
                            color: isSelected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) : Theme.bg1
                            border.color: isSelected ? Theme.accent : (pMouse.containsMouse ? Theme.accent : Theme.bg2)
                            border.width: isSelected ? 1.5 : 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: modelData.icon
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    color: parent.parent.isSelected ? Theme.accent : Theme.silver
                                }
                                Text {
                                    text: modelData.label
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.bold: true
                                    font.pixelSize: 10
                                    color: parent.parent.isSelected ? Theme.fg0 : Theme.fg1
                                }
                            }

                            MouseArea {
                                id: pMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsWindow.setAnimProfile(modelData.id)
                            }
                        }
                    }
                }
            }

            // SURFACE STYLE SWITCHER
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Surface Glass & Tone"
                    font.family: "JetBrainsMono Nerd Font"
                    font.bold: true
                    font.pixelSize: 11
                    color: Theme.silver
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 8
                        color: Theme.bg1
                        border.color: obsMouse.containsMouse ? Theme.accent : Theme.bg2
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰌶"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                color: Theme.accent
                            }
                            Text {
                                text: "Obsidian Black"
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                font.pixelSize: 10
                                color: Theme.fg0
                            }
                        }

                        MouseArea {
                            id: obsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                settingsWindow.runDetached(Quickshell.env("HOME") + "/.config/hypr/scripts/theme-switcher.sh --surface obsidian")
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 8
                        color: Theme.bg1
                        border.color: matMouse.containsMouse ? Theme.accent : Theme.bg2
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰏘"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                color: Theme.accent
                            }
                            Text {
                                text: "Material Tint"
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                font.pixelSize: 10
                                color: Theme.fg0
                            }
                        }

                        MouseArea {
                            id: matMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                settingsWindow.runDetached(Quickshell.env("HOME") + "/.config/hypr/scripts/theme-switcher.sh --surface material")
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

            // FOOTER ACTIONS
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    height: 34
                    Layout.preferredWidth: 160
                    radius: 8
                    color: resetMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: Theme.bg3
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰦛"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            color: Theme.silver
                        }
                        Text {
                            text: "Reset Defaults"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: Theme.fg1
                        }
                    }

                    MouseArea {
                        id: resetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsWindow.resetDefaults()
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    height: 34
                    Layout.preferredWidth: 100
                    radius: 8
                    color: Theme.accent
                    Text {
                        anchors.centerIn: parent
                        text: "Done"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 11
                        color: Theme.bg0
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsWindow.close()
                    }
                }
            }
        }
    }
}
