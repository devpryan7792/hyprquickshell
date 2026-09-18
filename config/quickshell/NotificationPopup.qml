import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: popupWindow

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }

    margins {
        top: 48
        right: 14
    }

    implicitWidth: 350
    implicitHeight: popupColumn.implicitHeight + 10
    color: "transparent"

    visible: NotificationManager.popupList.length > 0

    Column {
        id: popupColumn
        width: parent.width
        spacing: 10

        Repeater {
            model: NotificationManager.popupList

            delegate: Rectangle {
                id: notifCard
                width: popupColumn.width
                implicitHeight: cardLayout.implicitHeight + 20
                radius: 10
                color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.95)
                border.color: modelData.urgency === 2 ? Theme.red : (cardHover.containsMouse ? Theme.accent : Theme.bg3)
                border.width: modelData.urgency === 2 ? 2 : 1

                property bool isHovered: cardHover.containsMouse
                property int remainingMs: 5000

                Timer {
                    id: dismissTimer
                    interval: 100
                    repeat: true
                    running: !notifCard.isHovered && modelData.urgency !== 2
                    onTriggered: {
                        notifCard.remainingMs -= 100
                        if (notifCard.remainingMs <= 0) {
                            dismissTimer.stop()
                            NotificationManager.dismissPopup(modelData.id)
                        }
                    }
                }

                MouseArea {
                    id: cardHover
                    anchors.fill: parent
                    hoverEnabled: true
                }

                ColumnLayout {
                    id: cardLayout
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 12
                    }
                    spacing: 8

                    // Header row: App icon, App name, Time, Close button
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // App Icon or generic notification icon
                        Rectangle {
                            width: 22
                            height: 22
                            radius: 4
                            color: Theme.bg2

                            Text {
                                anchors.centerIn: parent
                                text: modelData.urgency === 2 ? "󰀦" : "󰂚"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                color: modelData.urgency === 2 ? Theme.red : Theme.accent
                            }
                        }

                        Text {
                            text: modelData.appName
                            font.family: "JetBrainsMono Nerd Font"
                            font.bold: true
                            font.pixelSize: 11
                            color: Theme.fg2
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.timeStr
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: Theme.gray
                        }

                        // Close button
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 4
                            color: closeHover.containsMouse ? Theme.bg3 : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: closeHover.containsMouse ? Theme.red : Theme.gray
                            }

                            MouseArea {
                                id: closeHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationManager.dismissPopup(modelData.id)
                            }
                        }
                    }

                    // Summary / Title
                    Text {
                        text: modelData.summary
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 13
                        color: Theme.fg0
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }

                    // Body
                    Text {
                        text: modelData.body
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Theme.fg1
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }

                    // Actions Row (if any)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: modelData.actions && modelData.actions.length > 0

                        Repeater {
                            model: modelData.actions

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 26
                                radius: 4
                                color: actMouse.containsMouse ? Theme.bg3 : Theme.bg2
                                border.color: actMouse.containsMouse ? Theme.accent : Theme.bg3
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.text
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: actMouse.containsMouse ? Theme.accent : Theme.fg1
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: actMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        try {
                                            modelData.invoke()
                                        } catch(e) {}
                                        NotificationManager.dismissPopup(notifCard.modelData.id)
                                    }
                                }
                            }
                        }
                    }

                    // Progress timeout bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        radius: 1
                        color: Theme.bg3
                        visible: modelData.urgency !== 2

                        Rectangle {
                            height: parent.height
                            radius: 1
                            color: modelData.urgency === 2 ? Theme.red : Theme.accent
                            width: parent.width * (Math.max(0, notifCard.remainingMs) / 5000.0)
                        }
                    }
                }
            }
        }
    }
}
