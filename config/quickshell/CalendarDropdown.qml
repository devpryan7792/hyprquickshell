import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io

PanelWindow {
    id: calWindow

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
        calWindow.requestClose()
    }

    // Backdrop click-to-dismiss
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: calWindow.close()
        }
    }

    // State for viewing month/year
    property var today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth() // 0-11

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var dayLabels: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0
            viewYear++
        } else {
            viewMonth++
        }
    }

    function prevMonth() {
        if (viewMonth === 0) {
            viewMonth = 11
            viewYear--
        } else {
            viewMonth--
        }
    }

    function resetToday() {
        let now = new Date()
        viewYear = now.getFullYear()
        viewMonth = now.getMonth()
    }

    // Compute 42 calendar cell days
    property var calendarGrid: {
        let firstDay = new Date(viewYear, viewMonth, 1).getDay()
        let startOffset = (firstDay + 6) % 7 // Monday = 0
        let daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate()
        let daysInPrev = new Date(viewYear, viewMonth, 0).getDate()

        let cells = []
        let now = new Date()
        let realYear = now.getFullYear()
        let realMonth = now.getMonth()
        let realDate = now.getDate()

        // Days from previous month
        for (let i = startOffset - 1; i >= 0; i--) {
            cells.push({
                dayNumber: daysInPrev - i,
                isCurrentMonth: false,
                isToday: false
            })
        }

        // Days of current view month
        for (let i = 1; i <= daysInMonth; i++) {
            let isCurrent = (viewYear === realYear && viewMonth === realMonth && i === realDate)
            cells.push({
                dayNumber: i,
                isCurrentMonth: true,
                isToday: isCurrent
            })
        }

        // Days of next month to fill 42 cells (6 full rows)
        let remaining = 42 - cells.length
        for (let i = 1; i <= remaining; i++) {
            cells.push({
                dayNumber: i,
                isCurrentMonth: false,
                isToday: false
            })
        }

        return cells
    }

    // Read system uptime
    property string uptimeStr: "up"
    Process {
        id: uptimeProc
        command: ["sh", "-c", "uptime -p 2>/dev/null || echo 'up'"]
        stdout: SplitParser {
            onRead: data => {
                let s = data.trim()
                if (s.length > 0) calWindow.uptimeStr = s
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            resetToday()
            uptimeProc.running = true
        }
    }

    // The Calendar Card
    Rectangle {
        id: card
        width: 330
        height: 370
        anchors.top: parent.top
        anchors.topMargin: 46
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 8
        color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.96)
        border.color: Theme.accent
        border.width: 1
        clip: true

        opacity: calWindow.visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 50 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // Header: Month, Year, and Navigation Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: calWindow.monthNames[calWindow.viewMonth] + " " + calWindow.viewYear
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    color: Theme.fg0
                    Layout.fillWidth: true
                }

                // Today jump button
                Rectangle {
                    height: 24
                    implicitWidth: 50
                    radius: 4
                    color: Theme.bg1
                    border.color: Theme.bg3
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Today"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calWindow.resetToday()
                    }
                }

                // Prev Month Button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 4
                    color: prevMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: prevMouse.containsMouse ? Theme.accent : Theme.bg3
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰅁"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: Theme.fg1
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calWindow.prevMonth()
                    }
                }

                // Next Month Button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 4
                    color: nextMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: nextMouse.containsMouse ? Theme.accent : Theme.bg3
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰅂"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: Theme.fg1
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calWindow.nextMonth()
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.bg3
            }

            // Days of Week Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: calWindow.dayLabels
                    Item {
                        Layout.fillWidth: true
                        height: 20
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.silver
                        }
                    }
                }
            }

            // Calendar Grid (7 columns x 6 rows)
            Grid {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                spacing: 2

                Repeater {
                    model: calWindow.calendarGrid

                    Rectangle {
                        width: (card.width - 32 - 12) / 7
                        height: 28
                        radius: 4
                        color: modelData.isToday
                               ? Theme.accent
                               : (cellMouse.containsMouse ? Theme.bg2 : "transparent")
                        border.color: (modelData.isToday)
                                      ? Theme.accent
                                      : (cellMouse.containsMouse ? Theme.bg3 : "transparent")
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: String(modelData.dayNumber)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.bold: modelData.isToday
                            color: modelData.isToday
                                   ? Theme.bg0
                                   : (modelData.isCurrentMonth ? Theme.fg0 : Theme.gray)
                        }

                        MouseArea {
                            id: cellMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }

            // Footer: Uptime & Time info
            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 4
                color: Theme.bg1
                border.color: Theme.bg3
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8

                    Text {
                        text: "󰥔 " + calWindow.uptimeStr
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: Theme.silver
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "Esc / Click to close"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        color: Theme.gray
                    }
                }
            }
        }

        // Close on Escape key
        Item {
            focus: calWindow.visible
            Keys.onEscapePressed: calWindow.close()
        }
    }
}
