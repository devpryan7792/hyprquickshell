import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: sessionWindow

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
        sessionWindow.requestClose()
    }

    // Non-blocking detached launcher
    Process {
        id: sessionProc
        property var cmd: []
        command: cmd
    }

    function executeAction(cmdStr) {
        sessionWindow.close()
        sessionProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/launch-app.sh", cmdStr]
        sessionProc.running = true
    }

    // Escape key handler to cancel safely
    Item {
        anchors.fill: parent
        focus: sessionWindow.visible
        Keys.onEscapePressed: sessionWindow.close()
    }

    // Fullscreen dimmed backdrop (Click anywhere outside to cancel)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)
        opacity: sessionWindow.visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: sessionWindow.close()
        }
    }

    // Centered Session Dialog Container
    Item {
        anchors.centerIn: parent
        width: contentLayout.implicitWidth
        height: contentLayout.implicitHeight

        scale: sessionWindow.visible ? 1.0 : 0.92
        opacity: sessionWindow.visible ? 1.0 : 0.0
        Behavior on scale {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: contentLayout
            spacing: 24
            Layout.alignment: Qt.AlignHCenter

            // Header Greeting & Instructions
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: Theme.bg1
                        border.color: Theme.accent
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "󰣇"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            color: Theme.accent
                        }
                    }

                    Text {
                        text: "Session Manager"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 18
                        color: Theme.fg0
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Select an action below or click outside / press Esc to cancel"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: Theme.silver
                }
            }

            // Cards Row (5 Action Tiles)
            RowLayout {
                spacing: 16
                Layout.alignment: Qt.AlignHCenter

                // 1. LOCK
                Rectangle {
                    width: 115
                    height: 135
                    radius: 12
                    color: lockMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: lockMouse.containsMouse ? Theme.accent : Theme.bg3
                    border.width: lockMouse.containsMouse ? 1.5 : 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 50
                            height: 50
                            radius: 25
                            color: lockMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : Theme.bg2
                            Text {
                                anchors.centerIn: parent
                                text: "󰌾"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 22
                                color: Theme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 2
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Lock"
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                font.pixelSize: 13
                                color: Theme.fg0
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "hyprlock"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                color: Theme.silver
                            }
                        }
                    }

                    MouseArea {
                        id: lockMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sessionWindow.executeAction("hyprlock")
                    }
                }

                // 2. SLEEP / SUSPEND
                Rectangle {
                    width: 115
                    height: 135
                    radius: 12
                    color: sleepMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: sleepMouse.containsMouse ? Theme.secondary : Theme.bg3
                    border.width: sleepMouse.containsMouse ? 1.5 : 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 50
                            height: 50
                            radius: 25
                            color: sleepMouse.containsMouse ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.2) : Theme.bg2
                            Text {
                                anchors.centerIn: parent
                                text: "󰒲"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 22
                                color: Theme.secondary
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 2
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Sleep"
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                font.pixelSize: 13
                                color: Theme.fg0
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Suspend"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                color: Theme.silver
                            }
                        }
                    }

                    MouseArea {
                        id: sleepMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sessionWindow.executeAction("systemctl suspend")
                    }
                }

                // 3. LOGOUT / EXIT
                Rectangle {
                    width: 115
                    height: 135
                    radius: 12
                    color: logoutMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: logoutMouse.containsMouse ? Theme.tertiary : Theme.bg3
                    border.width: logoutMouse.containsMouse ? 1.5 : 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 50
                            height: 50
                            radius: 25
                            color: logoutMouse.containsMouse ? Qt.rgba(Theme.tertiary.r, Theme.tertiary.g, Theme.tertiary.b, 0.2) : Theme.bg2
                            Text {
                                anchors.centerIn: parent
                                text: "󰍃"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 22
                                color: Theme.tertiary
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 2
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Logout"
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                font.pixelSize: 13
                                color: Theme.fg0
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Exit Hyprland"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                color: Theme.silver
                            }
                        }
                    }

                    MouseArea {
                        id: logoutMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sessionWindow.executeAction("hyprctl dispatch exit")
                    }
                }

                // 4. REBOOT
                Rectangle {
                    width: 115
                    height: 135
                    radius: 12
                    color: rebootMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: rebootMouse.containsMouse ? Theme.yellow : Theme.bg3
                    border.width: rebootMouse.containsMouse ? 1.5 : 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 50
                            height: 50
                            radius: 25
                            color: rebootMouse.containsMouse ? Qt.rgba(Theme.yellow.r, Theme.yellow.g, Theme.yellow.b, 0.2) : Theme.bg2
                            Text {
                                anchors.centerIn: parent
                                text: "󰜉"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 22
                                color: Theme.yellow
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 2
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Restart"
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                font.pixelSize: 13
                                color: Theme.fg0
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Reboot PC"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                color: Theme.silver
                            }
                        }
                    }

                    MouseArea {
                        id: rebootMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sessionWindow.executeAction("systemctl reboot")
                    }
                }

                // 5. SHUTDOWN / POWER OFF
                Rectangle {
                    width: 115
                    height: 135
                    radius: 12
                    color: offMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15) : Theme.bg1
                    border.color: offMouse.containsMouse ? Theme.red : Theme.bg3
                    border.width: offMouse.containsMouse ? 1.5 : 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 50
                            height: 50
                            radius: 25
                            color: offMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.25) : Theme.bg2
                            Text {
                                anchors.centerIn: parent
                                text: "󰐥"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 22
                                color: Theme.red
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 2
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Power Off"
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                font.pixelSize: 13
                                color: Theme.fg0
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Shut Down"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                color: Theme.silver
                            }
                        }
                    }

                    MouseArea {
                        id: offMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sessionWindow.executeAction("systemctl poweroff")
                    }
                }
            }

            // Cancel Button Bottom Pill
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 110
                height: 32
                radius: 16
                color: cancelBtnMouse.containsMouse ? Theme.bg3 : Theme.bg1
                border.color: cancelBtnMouse.containsMouse ? Theme.accent : Theme.bg3
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "󰅖"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: cancelBtnMouse.containsMouse ? Theme.red : Theme.silver
                    }
                    Text {
                        text: "Cancel"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        color: cancelBtnMouse.containsMouse ? Theme.fg0 : Theme.silver
                    }
                }

                MouseArea {
                    id: cancelBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sessionWindow.close()
                }
            }
        }
    }
}
