import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Io

PanelWindow {
    id: dashboardWindow

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
    property string currentTab: "notifications"

    function close() {
        dashboardWindow.requestClose()
    }

    // Helper command executor
    Process {
        id: execProc
        property var cmd: []
        command: cmd
    }

    function run(cmdList) {
        execProc.command = cmdList
        execProc.running = true
        dashboardWindow.close()
    }

    function runSilent(cmdList) {
        execProc.command = cmdList
        execProc.running = true
    }

    // Backdrop click outside to close
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        opacity: dashboardWindow.visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        MouseArea {
            anchors.fill: parent
            onClicked: dashboardWindow.close()
        }
    }

    // Active player accessor
    property var player: (Mpris.players && Mpris.players.values && Mpris.players.values.length > 0)
                         ? Mpris.players.values[0]
                         : null

    // Hardware Sensors
    property int hwCpu: 0
    property int hwRam: 0
    property string hwRamStr: "0G / 0G"
    property int hwDisk: 0
    property string hwDiskStr: "0G / 0G"
    property var topProcs: []
    property bool showProcessList: false

    Process {
        id: hwStatsProc
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/hw-stats.py"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let d = JSON.parse(data)
                    dashboardWindow.hwCpu = d.cpu_pct ?? 0
                    dashboardWindow.hwRam = d.ram_pct ?? 0
                    dashboardWindow.hwRamStr = d.ram_str ?? "0G / 0G"
                    dashboardWindow.hwDisk = d.disk_pct ?? 0
                    dashboardWindow.hwDiskStr = d.disk_str ?? "0G / 0G"
                    dashboardWindow.topProcs = d.top_procs ?? []
                } catch (e) {}
            }
        }
    }

    // Night Light state
    property string nightLightState: "off"
    property string nightLightLabel: "Off"

    Process {
        id: dbNightLightReader
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/bluelight.sh", "status"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let d = JSON.parse(data)
                    dashboardWindow.nightLightState = d.state ?? "off"
                    dashboardWindow.nightLightLabel = d.label ?? "Off"
                } catch(e) {}
            }
        }
    }

    function setNightLight(temp) {
        dashboardWindow.runSilent([Quickshell.env("HOME") + "/.config/hypr/scripts/bluelight.sh", "set", temp])
        dashboardWindow.nightLightState = temp
        dashboardWindow.nightLightLabel = (temp === "off") ? "Off" : temp + "K"
    }

    Timer {
        interval: 3000
        running: dashboardWindow.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            hwStatsProc.running = true
            dbNightLightReader.running = true
        }
    }

    // Slide-out Drawer from right edge
    Rectangle {
        id: drawer
        width: 360
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 8
        radius: 8
        color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.96)
        border.color: Theme.accent
        border.width: 1
        clip: true

        transform: Translate {
            x: dashboardWindow.visible ? 0 : 380
            Behavior on x { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        }

        // Catch Esc
        Item {
            anchors.fill: parent
            focus: dashboardWindow.visible
            Keys.onEscapePressed: dashboardWindow.close()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 16

            // Header with Segmented Tab Switcher (Notifications & Controls)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    height: 32
                    Layout.fillWidth: true
                    radius: 6
                    color: Theme.bg1
                    border.color: Theme.bg3
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        spacing: 2

                        // Notifications Tab Button
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: dashboardWindow.currentTab === "notifications" ? Theme.bg3 : (notifTabMouse.containsMouse ? Theme.bg2 : "transparent")
                            border.color: dashboardWindow.currentTab === "notifications" ? Theme.accent : "transparent"
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "󰂚"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    color: dashboardWindow.currentTab === "notifications" ? Theme.accent : Theme.gray
                                }

                                Text {
                                    text: "Notifications"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.bold: dashboardWindow.currentTab === "notifications"
                                    font.pixelSize: 11
                                    color: dashboardWindow.currentTab === "notifications" ? Theme.fg0 : Theme.fg2
                                }

                                Rectangle {
                                    visible: NotificationManager.unreadCount > 0
                                    width: Math.max(14, tabBadgeText.implicitWidth + 6)
                                    height: 14
                                    radius: 7
                                    color: Theme.accent
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        id: tabBadgeText
                                        anchors.centerIn: parent
                                        text: NotificationManager.unreadCount
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: Theme.bg0
                                    }
                                }
                            }

                            MouseArea {
                                id: notifTabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dashboardWindow.currentTab = "notifications"
                            }
                        }

                        // Controls Tab Button
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: dashboardWindow.currentTab === "controls" ? Theme.bg3 : (ctrlTabMouse.containsMouse ? Theme.bg2 : "transparent")
                            border.color: dashboardWindow.currentTab === "controls" ? Theme.accent : "transparent"
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "󰍜"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    color: dashboardWindow.currentTab === "controls" ? Theme.accent : Theme.gray
                                }

                                Text {
                                    text: "Controls"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.bold: dashboardWindow.currentTab === "controls"
                                    font.pixelSize: 11
                                    color: dashboardWindow.currentTab === "controls" ? Theme.fg0 : Theme.fg2
                                }
                            }

                            MouseArea {
                                id: ctrlTabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dashboardWindow.currentTab = "controls"
                            }
                        }
                    }
                }

                // Close Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 6
                    color: closeMouse.containsMouse ? Theme.bg3 : Theme.bg1
                    border.color: closeMouse.containsMouse ? Theme.accent : Theme.bg3
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: closeMouse.containsMouse ? Theme.red : Theme.silver
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dashboardWindow.close()
                    }
                }
            }

            // ================= NOTIFICATIONS TAB VIEW =================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12
                visible: dashboardWindow.currentTab === "notifications"

                // Subheader: Inbox title + DND toggle + Clear All
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Inbox (" + NotificationManager.unreadCount + ")"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 13
                        color: Theme.fg1
                    }

                    Item { Layout.fillWidth: true }

                    // DND Toggle Button
                    Rectangle {
                        height: 26
                        width: 68
                        radius: 4
                        color: NotificationManager.dnd ? Theme.red : (dndBtnMouse.containsMouse ? Theme.bg3 : Theme.bg2)
                        border.color: NotificationManager.dnd ? Theme.red : Theme.bg3
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: NotificationManager.dnd ? "󰂛" : "󰂚"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: NotificationManager.dnd ? Theme.bg0 : Theme.fg0
                            }
                            Text {
                                text: "DND"
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                font.pixelSize: 10
                                color: NotificationManager.dnd ? Theme.bg0 : Theme.fg0
                            }
                        }

                        MouseArea {
                            id: dndBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationManager.toggleDnd()
                        }
                    }

                    // Clear All Button
                    Rectangle {
                        height: 26
                        width: 78
                        radius: 4
                        visible: NotificationManager.unreadCount > 0
                        color: clearBtnMouse.containsMouse ? Theme.bg3 : Theme.bg2
                        border.color: clearBtnMouse.containsMouse ? Theme.red : Theme.bg3
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "󰅖"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: clearBtnMouse.containsMouse ? Theme.red : Theme.gray
                            }
                            Text {
                                text: "Clear All"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: clearBtnMouse.containsMouse ? Theme.red : Theme.fg1
                            }
                        }

                        MouseArea {
                            id: clearBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationManager.clearAll()
                        }
                    }
                }

                // Empty state placeholder
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: NotificationManager.unreadCount === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰂚"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 42
                            color: Theme.bg3
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No Notifications"
                            font.family: "JetBrainsMono Nerd Font"
                            font.bold: true
                            font.pixelSize: 14
                            color: Theme.gray
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "You're all caught up!"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: Theme.silver
                        }
                    }
                }

                // Notification History List
                ListView {
                    id: notifHistoryList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    visible: NotificationManager.unreadCount > 0
                    model: NotificationManager.historyList
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        width: notifHistoryList.width
                        implicitHeight: cardInnerLayout.implicitHeight + 20
                        radius: 8
                        color: Theme.bg1
                        border.color: modelData.urgency === 2 ? Theme.red : (itemHoverArea.containsMouse ? Theme.accent : Theme.bg3)
                        border.width: modelData.urgency === 2 ? 2 : 1

                        MouseArea {
                            id: itemHoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        ColumnLayout {
                            id: cardInnerLayout
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: 10
                            }
                            spacing: 6

                            // Card header: Icon, App Name, Time, Dismiss button
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 4
                                    color: Theme.bg2

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.urgency === 2 ? "󰀦" : "󰂚"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
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

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 3
                                    color: itemDismissHover.containsMouse ? Theme.bg3 : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        color: itemDismissHover.containsMouse ? Theme.red : Theme.gray
                                    }

                                    MouseArea {
                                        id: itemDismissHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotificationManager.removeNotification(modelData.id)
                                    }
                                }
                            }

                            // Summary
                            Text {
                                text: modelData.summary
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                font.pixelSize: 12
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

                            // Action buttons
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                visible: modelData.actions && modelData.actions.length > 0

                                Repeater {
                                    model: modelData.actions

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 24
                                        radius: 4
                                        color: actionBtnMouse.containsMouse ? Theme.bg3 : Theme.bg2
                                        border.color: actionBtnMouse.containsMouse ? Theme.accent : Theme.bg3
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.text
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: actionBtnMouse.containsMouse ? Theme.accent : Theme.fg1
                                            elide: Text.ElideRight
                                        }

                                        MouseArea {
                                            id: actionBtnMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                try { modelData.invoke() } catch(e) {}
                                                NotificationManager.removeNotification(modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ================= CONTROLS TAB VIEW =================
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: controlsCol.implicitHeight
                clip: true
                visible: dashboardWindow.currentTab === "controls"
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: controlsCol
                    width: parent.width
                    spacing: 16

            // Quick App Launchers Grid
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Terminal
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 6
                    color: termMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: termMouse.containsMouse ? Theme.accent : Theme.bg3
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰞷"; font.family: "JetBrainsMono Nerd Font"; color: Theme.accent; font.pixelSize: 14 }
                        Text { text: "Terminal"; font.family: "JetBrainsMono Nerd Font"; color: Theme.fg1; font.pixelSize: 11; font.bold: true }
                    }
                    MouseArea {
                        id: termMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dashboardWindow.run(["ghostty"])
                    }
                }

                // File Manager
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 6
                    color: fmMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: fmMouse.containsMouse ? Theme.accent : Theme.bg3
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰉋"; font.family: "JetBrainsMono Nerd Font"; color: Theme.secondary; font.pixelSize: 14 }
                        Text { text: "Files"; font.family: "JetBrainsMono Nerd Font"; color: Theme.fg1; font.pixelSize: 11; font.bold: true }
                    }
                    MouseArea {
                        id: fmMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dashboardWindow.run(["dolphin"])
                    }
                }

                // Browser
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 6
                    color: webMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: webMouse.containsMouse ? Theme.accent : Theme.bg3
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰈹"; font.family: "JetBrainsMono Nerd Font"; color: Theme.accent; font.pixelSize: 14 }
                        Text { text: "Browser"; font.family: "JetBrainsMono Nerd Font"; color: Theme.fg1; font.pixelSize: 11; font.bold: true }
                    }
                    MouseArea {
                        id: webMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dashboardWindow.run(["firefox"])
                    }
                }
            }

            // System Hardware Resources Card (Expandable Process Inspector)
            Rectangle {
                id: hwCard
                Layout.fillWidth: true
                implicitHeight: dashboardWindow.showProcessList ? 300 : 106
                Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                radius: 8
                color: Theme.bg1
                border.color: dashboardWindow.showProcessList ? Theme.teal : Theme.bg3
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰍛 System Performance"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.fg1
                            Layout.fillWidth: true
                        }

                        // Open btop button
                        Rectangle {
                            height: 20
                            implicitWidth: 54
                            radius: 3
                            color: btopMouse.containsMouse ? Theme.bg2 : "transparent"
                            border.color: btopMouse.containsMouse ? Theme.accent : Theme.bg3
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 3
                                Text { text: "󰒓"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: Theme.accent }
                                Text { text: "btop"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true; color: Theme.fg1 }
                            }

                            MouseArea {
                                id: btopMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dashboardWindow.run(["ghostty", "-e", "btop"])
                            }
                        }
                    }

                    // CPU Row
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "󰍛 CPU"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Theme.silver }
                            Item { Layout.fillWidth: true }
                            Text { text: dashboardWindow.hwCpu + "%"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; color: Theme.accent }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            radius: 2
                            color: Theme.bg2
                            Rectangle {
                                width: parent.width * (Math.min(100, Math.max(0, dashboardWindow.hwCpu)) / 100.0)
                                height: parent.height
                                radius: 2
                                color: Theme.accent
                                Behavior on width { NumberAnimation { duration: 250 } }
                            }
                        }
                    }

                    // RAM Row (Clickable to inspect processes)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 4
                        color: ramMouse.containsMouse ? Theme.bg2 : "transparent"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "󰘚 Memory"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Theme.silver }
                                Text {
                                    text: dashboardWindow.showProcessList ? "󰅃 (collapse)" : "󰅀 (click to inspect)"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    color: dashboardWindow.showProcessList ? Theme.teal : Theme.gray
                                }
                                Item { Layout.fillWidth: true }
                                Text { text: dashboardWindow.hwRamStr + " (" + dashboardWindow.hwRam + "%)"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; color: Theme.teal }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 4
                                radius: 2
                                color: Theme.bg2
                                Rectangle {
                                    width: parent.width * (Math.min(100, Math.max(0, dashboardWindow.hwRam)) / 100.0)
                                    height: parent.height
                                    radius: 2
                                    color: Theme.teal
                                    Behavior on width { NumberAnimation { duration: 250 } }
                                }
                            }
                        }

                        MouseArea {
                            id: ramMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dashboardWindow.showProcessList = !dashboardWindow.showProcessList
                        }
                    }

                    // Disk Storage Row
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "󰋊 Root Storage"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Theme.silver }
                            Item { Layout.fillWidth: true }
                            Text { text: dashboardWindow.hwDiskStr + " (" + dashboardWindow.hwDisk + "%)"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; color: Theme.purple }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            radius: 2
                            color: Theme.bg2
                            Rectangle {
                                width: parent.width * (Math.min(100, Math.max(0, dashboardWindow.hwDisk)) / 100.0)
                                height: parent.height
                                radius: 2
                                color: Theme.purple
                                Behavior on width { NumberAnimation { duration: 250 } }
                            }
                        }
                    }

                    // Expanded Process Inspector Section
                    ColumnLayout {
                        visible: dashboardWindow.showProcessList
                        Layout.fillWidth: true
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.bg3
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "󰘚 Top Memory Consumers"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.teal
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "Click 󰅖 to kill"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                color: Theme.gray
                            }
                        }

                        Repeater {
                            model: dashboardWindow.topProcs

                            Rectangle {
                                Layout.fillWidth: true
                                height: 24
                                radius: 4
                                color: pMouse.containsMouse ? Theme.bg2 : Theme.bg0
                                border.color: pMouse.containsMouse ? Theme.teal : Theme.bg3
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    spacing: 6

                                    Text {
                                        text: String(index + 1) + "."
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        color: Theme.gray
                                    }

                                    Text {
                                        text: modelData.name
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.fg0
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: "#" + modelData.pid
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        color: Theme.gray
                                    }

                                    Text {
                                        text: modelData.mem + " (" + modelData.pct + ")"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: Theme.teal
                                    }

                                    // Kill process button
                                    Rectangle {
                                        width: 16
                                        height: 16
                                        radius: 3
                                        color: killMouse.containsMouse ? Theme.red : Theme.bg2

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            color: killMouse.containsMouse ? Theme.bg0 : Theme.silver
                                        }

                                        MouseArea {
                                            id: killMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                dashboardWindow.runSilent(["kill", "-9", String(modelData.pid)])
                                                hwStatsProc.running = true
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: pMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                    }
                }
            }

            // MPRIS Media Card
            Rectangle {
                Layout.fillWidth: true
                height: 125
                radius: 8
                color: Theme.bg1
                border.color: Theme.bg3
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Cover / Placeholder
                        Rectangle {
                            width: 48
                            height: 48
                            radius: 6
                            color: Theme.bg2
                            border.color: Theme.bg3
                            border.width: 1
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: (dashboardWindow.player && dashboardWindow.player.trackArtUrl) ? dashboardWindow.player.trackArtUrl : ""
                                fillMode: Image.PreserveAspectCrop
                                visible: source.toString().length > 0
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰝚"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 20
                                color: Theme.gray
                                visible: !dashboardWindow.player || !dashboardWindow.player.trackArtUrl
                            }
                        }

                        // Track details
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: (dashboardWindow.player && dashboardWindow.player.trackTitle) ? dashboardWindow.player.trackTitle : "No Media Playing"
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                font.pixelSize: 12
                                color: Theme.fg0
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: {
                                    if (!dashboardWindow.player) return "Idle"
                                    let arts = dashboardWindow.player.trackArtists
                                    if (Array.isArray(arts)) return arts.join(", ")
                                    if (typeof arts === "string" && arts.length > 0) return arts
                                    return dashboardWindow.player.trackArtist ?? "Unknown Artist"
                                }
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: Theme.silver
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Playback Controls
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Layout.alignment: Qt.AlignHCenter

                        // Prev
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 4
                            color: prevMouse.containsMouse ? Theme.bg3 : Theme.bg2
                            Text {
                                anchors.centerIn: parent
                                text: "󰒮"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: Theme.fg1
                            }
                            MouseArea {
                                id: prevMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (dashboardWindow.player) dashboardWindow.player.previous()
                            }
                        }

                        // Play/Pause
                        Rectangle {
                            width: 38
                            height: 32
                            radius: 6
                            color: Theme.accent
                            Text {
                                anchors.centerIn: parent
                                text: (dashboardWindow.player && dashboardWindow.player.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 15
                                color: Theme.bg0
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (dashboardWindow.player) dashboardWindow.player.togglePlaying()
                            }
                        }

                        // Next
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 4
                            color: nextMouse.containsMouse ? Theme.bg3 : Theme.bg2
                            Text {
                                anchors.centerIn: parent
                                text: "󰒭"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: Theme.fg1
                            }
                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (dashboardWindow.player) dashboardWindow.player.next()
                            }
                        }
                    }
                }
            }

            // Sliders Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                // Volume slider
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "󰕾 Volume"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: Theme.fg1 }
                        Item { Layout.fillWidth: true }
                        Text { text: Math.round(volSlider.value) + "%"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: Theme.accent }
                    }

                    Slider {
                        id: volSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: 50
                        onMoved: {
                            dashboardWindow.runSilent(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (value / 100).toFixed(2)])
                        }
                    }
                }

                // Brightness slider
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "󰃠 Brightness"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: Theme.fg1 }
                        Item { Layout.fillWidth: true }
                        Text { text: Math.round(briSlider.value) + "%"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: Theme.accent }
                    }

                    Slider {
                        id: briSlider
                        Layout.fillWidth: true
                        from: 5
                        to: 100
                        value: 75
                        onMoved: {
                            dashboardWindow.runSilent(["brightnessctl", "set", Math.round(value) + "%"])
                        }
                    }
                }
            }

            // Night Light / Blue Light Filter Quick Selector
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 8
                color: Theme.bg1
                border.color: dashboardWindow.nightLightState !== "off" ? "#e5c07b" : Theme.bg3
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 6

                    Row {
                        spacing: 6
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            text: "󰖔"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: dashboardWindow.nightLightState !== "off" ? "#e5c07b" : Theme.silver
                        }
                        Text {
                            text: "Night Light"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.fg1
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Segmented Pills: Off, 4500K, 3500K, 2700K
                    Row {
                        spacing: 4
                        Layout.alignment: Qt.AlignVCenter

                        Repeater {
                            model: [
                                { key: "off", label: "Off" },
                                { key: "4500", label: "4500K" },
                                { key: "3500", label: "3500K" },
                                { key: "2700", label: "2700K" }
                            ]
                            delegate: Rectangle {
                                width: 44
                                height: 26
                                radius: 5
                                color: dashboardWindow.nightLightState === modelData.key
                                       ? (modelData.key === "off" ? Theme.bg3 : Qt.rgba(0.9, 0.75, 0.48, 0.22))
                                       : (btnMouse.containsMouse ? Theme.bg2 : "transparent")
                                border.color: dashboardWindow.nightLightState === modelData.key
                                              ? (modelData.key === "off" ? Theme.silver : "#e5c07b")
                                              : (btnMouse.containsMouse ? Theme.bg3 : "transparent")
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    font.bold: dashboardWindow.nightLightState === modelData.key
                                    color: dashboardWindow.nightLightState === modelData.key
                                           ? (modelData.key === "off" ? Theme.fg0 : "#e5c07b")
                                           : Theme.fg2
                                }

                                MouseArea {
                                    id: btnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dashboardWindow.setNightLight(modelData.key)
                                }
                            }
                        }
                    }
                }
            }

            // ================= MATERIAL YOU PALETTE & THEME ENGINE =================
            Rectangle {
                Layout.fillWidth: true
                height: 152
                radius: 8
                color: Theme.bg1
                border.color: Theme.bg3
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    // Header row
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰸉  Material You Palette"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.fg0
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Click swatch to copy"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            color: Theme.gray
                        }
                    }

                    // Dynamic Color Swatches Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Repeater {
                            model: [
                                { label: "Accent", colorVal: Theme.accent },
                                { label: "Second", colorVal: Theme.secondary },
                                { label: "Tert",   colorVal: Theme.tertiary },
                                { label: "Surface",colorVal: Theme.bg2 },
                                { label: "Base",   colorVal: Theme.bg0 },
                                { label: "Muted",  colorVal: Theme.silver }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                height: 34
                                radius: 4
                                color: modelData.colorVal
                                border.color: swatchMouse.containsMouse ? Theme.fg0 : Theme.bg3
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: (index === 0 || index === 1 || index === 2) ? "#111318" : "#e1e2e9"
                                }

                                MouseArea {
                                    id: swatchMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        dashboardWindow.runSilent(["wl-copy", modelData.colorVal.toString()])
                                    }
                                }
                            }
                        }
                    }

                    // Scheme Variant Switchers
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Repeater {
                            model: [
                                { name: "Vibrant",    scheme: "scheme-vibrant" },
                                { name: "Tonal",      scheme: "scheme-tonal-spot" },
                                { name: "Expressive", scheme: "scheme-expressive" },
                                { name: "Rainbow",    scheme: "scheme-rainbow" }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                height: 26
                                radius: 4
                                color: schemeMouse.containsMouse ? Theme.bg3 : Theme.bg2
                                border.color: schemeMouse.containsMouse ? Theme.accent : Theme.bg3
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    color: schemeMouse.containsMouse ? Theme.accent : Theme.fg1
                                }

                                MouseArea {
                                    id: schemeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        dashboardWindow.runSilent([Quickshell.env("HOME") + "/.config/hypr/scripts/theme-switcher.sh", "--scheme", modelData.scheme])
                                    }
                                }
                            }
                        }
                    }

                    // Random Theme Quick Button
                    Rectangle {
                        Layout.fillWidth: true
                        height: 26
                        radius: 4
                        color: randMouse.containsMouse ? Theme.bg3 : Theme.bg2
                        border.color: randMouse.containsMouse ? Theme.accent : Theme.bg3
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "󰒮"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: Theme.accent }
                            Text { text: "Shuffle Random Wallpaper & Theme"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; color: Theme.fg0 }
                        }

                        MouseArea {
                            id: randMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                dashboardWindow.runSilent([Quickshell.env("HOME") + "/.config/hypr/scripts/theme-switcher.sh"])
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // Power Actions Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Suspend
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 6
                    color: suspMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: suspMouse.containsMouse ? Theme.accent : Theme.bg3
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰒲"; font.family: "JetBrainsMono Nerd Font"; color: Theme.secondary; font.pixelSize: 14 }
                    }
                    MouseArea {
                        id: suspMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dashboardWindow.run(["systemctl", "suspend"])
                    }
                }

                // Reboot
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 6
                    color: rebMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: rebMouse.containsMouse ? Theme.accent : Theme.bg3
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰜉"; font.family: "JetBrainsMono Nerd Font"; color: Theme.tertiary; font.pixelSize: 14 }
                    }
                    MouseArea {
                        id: rebMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dashboardWindow.run(["systemctl", "reboot"])
                    }
                }

                // Poweroff
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 6
                    color: offMouse.containsMouse ? Theme.red : Theme.bg1
                    border.color: offMouse.containsMouse ? Theme.red : Theme.bg3
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰐥"; font.family: "JetBrainsMono Nerd Font"; color: offMouse.containsMouse ? Theme.bg0 : Theme.red; font.pixelSize: 14 }
                    }
                    MouseArea {
                        id: offMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dashboardWindow.run(["systemctl", "poweroff"])
                    }
                }
            }
        }
    }
}
}
}
