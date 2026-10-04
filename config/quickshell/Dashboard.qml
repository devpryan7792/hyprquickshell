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

    function close() {
        dashboardWindow.pendingPowerAction = ""
        dashboardWindow.requestClose()
    }

    // Active View Tab: "controls" or "notifications"
    property string currentTab: "controls"

    // Telemetry & Hardware States
    property int sysVol: 50
    property bool isMuted: false
    property int sysBri: 75
    property string wifiRadio: "enabled"
    property string wifiSsid: ""
    property string caffeineState: "off"
    property string nightLightState: "off"
    property string surfaceMode: "obsidian"
    property string activeScheme: "scheme-vibrant"
    property string uptimeStr: "Online"
    property string pendingPowerAction: "" // "", "reboot", "poweroff"

    // Hardware Sensors
    property int hwCpu: 0
    property int hwRam: 0
    property string hwRamStr: "0G / 0G"
    property int hwDisk: 0
    property string hwDiskStr: "0G / 0G"
    property var topProcs: []
    property bool showProcessList: false

    // Active player accessor
    property var player: (Mpris.players && Mpris.players.values && Mpris.players.values.length > 0)
                         ? Mpris.players.values[0]
                         : null

    // Non-blocking detached launcher (exits in <1ms, never locks Quickshell)
    Process {
        id: actionProc
        property var cmd: []
        command: cmd
    }

    function launchApp(execCmd) {
        dashboardWindow.close()
        actionProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/launch-app.sh", execCmd]
        actionProc.running = true
    }

    function runDetached(cmdStr) {
        actionProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/launch-app.sh", cmdStr]
        actionProc.running = true
    }

    // Debounced volume controller (prevents flooding Pipewire while dragging)
    Timer {
        id: volDebounce
        interval: 35
        repeat: false
        onTriggered: {
            runDetached("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (dashboardWindow.sysVol / 100).toFixed(2))
        }
    }

    // Debounced brightness controller
    Timer {
        id: briDebounce
        interval: 35
        repeat: false
        onTriggered: {
            runDetached("brightnessctl set " + dashboardWindow.sysBri + "%")
        }
    }

    // Comprehensive state sync process
    Process {
        id: stateSyncProc
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/dashboard-sync.sh"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let d = JSON.parse(data.trim())
                    if (!volSlider.pressed) dashboardWindow.sysVol = d.vol ?? 50
                    dashboardWindow.isMuted = (d.muted === true)
                    if (!briSlider.pressed) dashboardWindow.sysBri = d.bri ?? 75
                    dashboardWindow.wifiRadio = d.wifi_radio ?? "enabled"
                    dashboardWindow.wifiSsid = d.wifi_ssid ?? ""
                    dashboardWindow.caffeineState = d.caffeine ?? "off"
                    dashboardWindow.nightLightState = d.nightlight ?? "off"
                    dashboardWindow.surfaceMode = d.surface_mode ?? "obsidian"
                    dashboardWindow.activeScheme = d.scheme ?? "scheme-vibrant"
                    dashboardWindow.uptimeStr = d.uptime ?? "Online"
                } catch(e) {}
            }
        }
    }

    // Hardware resources process
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

    // Sync timer on visible
    Timer {
        interval: 2000
        running: dashboardWindow.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stateSyncProc.running = true
            hwStatsProc.running = true
        }
    }

    // Fluid backdrop dim with smooth cubic fade
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        opacity: dashboardWindow.visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: dashboardWindow.close()
        }
    }

    // Slide-out Bento Drawer from right edge (440px wide, macOS spring glide)
    Rectangle {
        id: drawer
        width: 440
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 12
        radius: 14
        color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.95)
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
        border.width: 1
        clip: true

        transform: Translate {
            x: dashboardWindow.visible ? 0 : 470
            Behavior on x {
                NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
            }
        }

        // Escape key handler
        Item {
            anchors.fill: parent
            focus: dashboardWindow.visible
            Keys.onEscapePressed: dashboardWindow.close()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // ================= HEADER ROW =================
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // OS & User pill
                Row {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: Theme.bg2
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

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Text {
                            text: "Arch Linux"
                            font.family: "JetBrainsMono Nerd Font"
                            font.bold: true
                            font.pixelSize: 12
                            color: Theme.fg0
                        }
                        Text {
                            text: "󰔚 Up " + dashboardWindow.uptimeStr
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            color: Theme.silver
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Segmented Tab Switcher (Controls vs Notifications)
                Rectangle {
                    height: 32
                    width: 190
                    radius: 7
                    color: Theme.bg1
                    border.color: Theme.bg3
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        spacing: 2
                        anchors.margins: 2

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
                                spacing: 4
                                Text {
                                    text: "󰍜"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    color: dashboardWindow.currentTab === "controls" ? Theme.accent : Theme.gray
                                }
                                Text {
                                    text: "Controls"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.bold: dashboardWindow.currentTab === "controls"
                                    font.pixelSize: 10
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
                                spacing: 4
                                Text {
                                    text: "󰂚"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    color: dashboardWindow.currentTab === "notifications" ? Theme.accent : Theme.gray
                                }
                                Text {
                                    text: "Alerts"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.bold: dashboardWindow.currentTab === "notifications"
                                    font.pixelSize: 10
                                    color: dashboardWindow.currentTab === "notifications" ? Theme.fg0 : Theme.fg2
                                }
                                Rectangle {
                                    visible: NotificationManager.unreadCount > 0
                                    width: Math.max(12, badgeText.implicitWidth + 4)
                                    height: 12
                                    radius: 6
                                    color: Theme.accent
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        id: badgeText
                                        anchors.centerIn: parent
                                        text: NotificationManager.unreadCount
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 8
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
                    }
                }

                // Close Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 7
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

            // ================= CONTROLS VIEW =================
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
                    spacing: 12

                    // 1. BENTO QUICK TOGGLES (2 Columns x 3 Rows)
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 8

                        // TILE 1: WiFi
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            radius: 8
                            readonly property bool isWifiOn: dashboardWindow.wifiRadio === "enabled"
                            color: isWifiOn ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12) : Theme.bg1
                            border.color: isWifiOn ? Theme.accent : (wifiMouse.containsMouse ? Theme.accent : Theme.bg3)
                            border.width: isWifiOn ? 1.5 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 6
                                    color: parent.parent.isWifiOn ? Theme.accent : Theme.bg2
                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.parent.parent.isWifiOn ? "󰤨" : "󰤭"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 14
                                        color: parent.parent.isWifiOn ? Theme.bg0 : Theme.silver
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: "Wi-Fi"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                        font.pixelSize: 11
                                        color: Theme.fg0
                                    }
                                    Text {
                                        text: dashboardWindow.wifiSsid.length > 0 ? dashboardWindow.wifiSsid : (parent.parent.parent.isWifiOn ? "Scanning..." : "Disabled")
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        color: parent.parent.parent.isWifiOn ? Theme.accent : Theme.silver
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                id: wifiMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let nextState = (dashboardWindow.wifiRadio === "enabled") ? "off" : "on"
                                    dashboardWindow.wifiRadio = (nextState === "on") ? "enabled" : "disabled"
                                    dashboardWindow.runDetached("nmcli radio wifi " + nextState)
                                    stateSyncProc.running = true
                                }
                            }
                        }

                        // TILE 2: Caffeine (Hypridle Inhibitor)
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            radius: 8
                            readonly property bool isCaffOn: dashboardWindow.caffeineState === "on"
                            color: isCaffOn ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.15) : Theme.bg1
                            border.color: isCaffOn ? Theme.secondary : (caffMouse.containsMouse ? Theme.accent : Theme.bg3)
                            border.width: isCaffOn ? 1.5 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 6
                                    color: parent.parent.isCaffOn ? Theme.secondary : Theme.bg2
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅶"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 14
                                        color: parent.parent.isCaffOn ? Theme.bg0 : Theme.silver
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: "Caffeine"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                        font.pixelSize: 11
                                        color: Theme.fg0
                                    }
                                    Text {
                                        text: parent.parent.isCaffOn ? "Awake (No Sleep)" : "Normal Sleep"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        color: parent.parent.isCaffOn ? Theme.secondary : Theme.silver
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                id: caffMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    dashboardWindow.caffeineState = (dashboardWindow.caffeineState === "on") ? "off" : "on"
                                    dashboardWindow.runDetached(Quickshell.env("HOME") + "/.config/hypr/scripts/caffeine.sh toggle")
                                }
                            }
                        }

                        // TILE 3: Night Light Filter
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            radius: 8
                            readonly property bool isNlOn: dashboardWindow.nightLightState !== "off"
                            color: isNlOn ? Qt.rgba(0.9, 0.75, 0.48, 0.16) : Theme.bg1
                            border.color: isNlOn ? "#e5c07b" : (nlMouse.containsMouse ? Theme.accent : Theme.bg3)
                            border.width: isNlOn ? 1.5 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 6
                                    color: parent.parent.isNlOn ? "#e5c07b" : Theme.bg2
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰖔"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 14
                                        color: parent.parent.isNlOn ? Theme.bg0 : Theme.silver
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: "Night Light"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                        font.pixelSize: 11
                                        color: Theme.fg0
                                    }
                                    Text {
                                        text: dashboardWindow.nightLightState === "off" ? "Off" : dashboardWindow.nightLightState + "K Warm"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        color: parent.parent.isNlOn ? "#e5c07b" : Theme.silver
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                id: nlMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    dashboardWindow.runDetached(Quickshell.env("HOME") + "/.config/hypr/scripts/bluelight.sh toggle")
                                    stateSyncProc.running = true
                                }
                            }
                        }

                        // TILE 4: Do Not Disturb
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            radius: 8
                            readonly property bool isDndOn: NotificationManager.dnd
                            color: isDndOn ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.16) : Theme.bg1
                            border.color: isDndOn ? Theme.red : (dndMouse.containsMouse ? Theme.accent : Theme.bg3)
                            border.width: isDndOn ? 1.5 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 6
                                    color: parent.parent.isDndOn ? Theme.red : Theme.bg2
                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.parent.isDndOn ? "󰂛" : "󰂚"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 14
                                        color: parent.parent.isDndOn ? Theme.bg0 : Theme.silver
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: "Do Not Disturb"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                        font.pixelSize: 11
                                        color: Theme.fg0
                                    }
                                    Text {
                                        text: parent.parent.isDndOn ? "Silenced" : "Alerts Active"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        color: parent.parent.isDndOn ? Theme.red : Theme.silver
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                id: dndMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationManager.toggleDnd()
                            }
                        }

                        // TILE 5: Screen Capture
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            radius: 8
                            color: Theme.bg1
                            border.color: capMouse.containsMouse ? Theme.accent : Theme.bg3
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 6
                                    color: Theme.bg2
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰄄"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 14
                                        color: Theme.accent
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: "Capture"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                        font.pixelSize: 11
                                        color: Theme.fg0
                                    }
                                    Text {
                                        text: "Region Screenshot"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        color: Theme.silver
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                id: capMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dashboardWindow.launchApp(Quickshell.env("HOME") + "/.config/hypr/scripts/screenshot.sh region")
                            }
                        }

                        // TILE 6: System Monitor (btop)
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            radius: 8
                            color: Theme.bg1
                            border.color: monMouse.containsMouse ? Theme.accent : Theme.bg3
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 6
                                    color: Theme.bg2
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰍛"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 14
                                        color: Theme.tertiary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: "Monitor"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                        font.pixelSize: 11
                                        color: Theme.fg0
                                    }
                                    Text {
                                        text: "Launch btop"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        color: Theme.silver
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                id: monMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dashboardWindow.launchApp("ghostty -e btop")
                            }
                        }
                    }

                    // 2. HARDWARE SLIDERS CARD (Volume & Brightness with Real Feedback)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 94
                        radius: 8
                        color: Theme.bg1
                        border.color: Theme.bg3
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            // Volume Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 4
                                    color: dashboardWindow.isMuted ? Theme.red : Theme.bg2
                                    Text {
                                        anchors.centerIn: parent
                                        text: dashboardWindow.isMuted ? "󰝟" : (dashboardWindow.sysVol > 50 ? "󰕾" : (dashboardWindow.sysVol > 0 ? "󰖀" : "󰕿"))
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        color: dashboardWindow.isMuted ? Theme.bg0 : Theme.accent
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            dashboardWindow.isMuted = !dashboardWindow.isMuted
                                            dashboardWindow.runDetached("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
                                            stateSyncProc.running = true
                                        }
                                    }
                                }

                                Slider {
                                    id: volSlider
                                    Layout.fillWidth: true
                                    from: 0
                                    to: 100
                                    value: dashboardWindow.sysVol
                                    onMoved: {
                                        dashboardWindow.sysVol = Math.round(value)
                                        dashboardWindow.isMuted = false
                                        volDebounce.restart()
                                    }
                                }

                                Text {
                                    text: dashboardWindow.isMuted ? "MUTED" : dashboardWindow.sysVol + "%"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: dashboardWindow.isMuted ? Theme.red : Theme.accent
                                    Layout.preferredWidth: 38
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            // Brightness Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 4
                                    color: Theme.bg2
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰃠"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        color: Theme.yellow
                                    }
                                }

                                Slider {
                                    id: briSlider
                                    Layout.fillWidth: true
                                    from: 5
                                    to: 100
                                    value: dashboardWindow.sysBri
                                    onMoved: {
                                        dashboardWindow.sysBri = Math.round(value)
                                        briDebounce.restart()
                                    }
                                }

                                Text {
                                    text: dashboardWindow.sysBri + "%"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Theme.yellow
                                    Layout.preferredWidth: 38
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }

                    // 3. NOW PLAYING MPRIS MEDIA CARD
                    Rectangle {
                        Layout.fillWidth: true
                        height: 98
                        radius: 8
                        color: Theme.bg1
                        border.color: Theme.bg3
                        border.width: 1
                        clip: true

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            // Album art thumbnail
                            Rectangle {
                                width: 52
                                height: 52
                                radius: 8
                                color: Theme.bg2
                                border.color: Theme.bg3
                                border.width: 1
                                clip: true

                                Image {
                                    sourceSize.width: 104
                                    sourceSize.height: 104
                                    asynchronous: true
                                    anchors.fill: parent
                                    source: (dashboardWindow.player && dashboardWindow.player.trackArtUrl) ? dashboardWindow.player.trackArtUrl : ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: source.toString().length > 0
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰝚"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 22
                                    color: Theme.silver
                                    visible: !dashboardWindow.player || !dashboardWindow.player.trackArtUrl
                                }
                            }

                            // Track metadata and playback buttons
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: (dashboardWindow.player && dashboardWindow.player.trackTitle) ? dashboardWindow.player.trackTitle : "No Media Playing"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.bold: true
                                    font.pixelSize: 11
                                    color: Theme.fg0
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: {
                                        if (!dashboardWindow.player) return "Idle Audio Session"
                                        let arts = dashboardWindow.player.trackArtists
                                        if (Array.isArray(arts)) return arts.join(", ")
                                        if (typeof arts === "string" && arts.length > 0) return arts
                                        return dashboardWindow.player.trackArtist ?? "Unknown Artist"
                                    }
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    color: Theme.silver
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                RowLayout {
                                    spacing: 12
                                    Layout.topMargin: 2

                                    // Prev
                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 4
                                        color: mPrevMouse.containsMouse ? Theme.bg3 : Theme.bg2
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰒮"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 12
                                            color: Theme.fg1
                                        }
                                        MouseArea {
                                            id: mPrevMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (dashboardWindow.player) dashboardWindow.player.previous()
                                        }
                                    }

                                    // Play / Pause
                                    Rectangle {
                                        width: 32
                                        height: 26
                                        radius: 5
                                        color: Theme.accent
                                        Text {
                                            anchors.centerIn: parent
                                            text: (dashboardWindow.player && dashboardWindow.player.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 13
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
                                        width: 26
                                        height: 26
                                        radius: 4
                                        color: mNextMouse.containsMouse ? Theme.bg3 : Theme.bg2
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰒭"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 12
                                            color: Theme.fg1
                                        }
                                        MouseArea {
                                            id: mNextMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (dashboardWindow.player) dashboardWindow.player.next()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 4. THEMING & SURFACE ENGINE CARD
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: themeCol.implicitHeight + 20
                        radius: 8
                        color: Theme.bg1
                        border.color: Theme.bg3
                        border.width: 1

                        ColumnLayout {
                            id: themeCol
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "󰸉 Theming & Surface Engine"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.bold: true
                                    font.pixelSize: 11
                                    color: Theme.fg0
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: "Click to apply live"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 8
                                    color: Theme.silver
                                }
                            }

                            // Surface Mode Switcher
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: [
                                        { name: "✦ Obsidian Stealth", mode: "obsidian" },
                                        { name: "🎨 Material Tinted", mode: "material" }
                                    ]

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 28
                                        radius: 4
                                        readonly property bool isActive: dashboardWindow.surfaceMode === modelData.mode
                                        color: isActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : (surfMouse.containsMouse ? Theme.bg3 : Theme.bg2)
                                        border.color: isActive ? Theme.accent : (surfMouse.containsMouse ? Theme.accent : Theme.bg3)
                                        border.width: isActive ? 1.5 : 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.name
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 10
                                            font.bold: isActive
                                            color: isActive ? Theme.accent : (surfMouse.containsMouse ? Theme.accent : Theme.fg1)
                                        }

                                        MouseArea {
                                            id: surfMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                dashboardWindow.surfaceMode = modelData.mode
                                                dashboardWindow.runDetached(Quickshell.env("HOME") + "/.config/hypr/scripts/theme-switcher.sh --surface " + modelData.mode)
                                            }
                                        }
                                    }
                                }
                            }

                            // Scheme Variants Switchers
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
                                        readonly property bool isActive: dashboardWindow.activeScheme === modelData.scheme
                                        color: isActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : (schemeMouse.containsMouse ? Theme.bg3 : Theme.bg2)
                                        border.color: isActive ? Theme.accent : (schemeMouse.containsMouse ? Theme.accent : Theme.bg3)
                                        border.width: isActive ? 1.5 : 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.name
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            font.bold: isActive
                                            color: isActive ? Theme.accent : (schemeMouse.containsMouse ? Theme.accent : Theme.fg1)
                                        }

                                        MouseArea {
                                            id: schemeMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                dashboardWindow.activeScheme = modelData.scheme
                                                dashboardWindow.runDetached(Quickshell.env("HOME") + "/.config/hypr/scripts/theme-switcher.sh --scheme " + modelData.scheme)
                                            }
                                        }
                                    }
                                }
                            }

                            // Palette Swatches
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

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
                                        height: 26
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
                                                dashboardWindow.runDetached("wl-copy " + modelData.colorVal.toString())
                                            }
                                        }
                                    }
                                }
                            }

                            // Wallpaper Random Shuffle Button
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
                                    Text { text: "Shuffle Random Wallpaper & Palette"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; color: Theme.fg0 }
                                }

                                MouseArea {
                                    id: randMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        dashboardWindow.runDetached(Quickshell.env("HOME") + "/.config/hypr/scripts/theme-switcher.sh")
                                    }
                                }
                            }
                        }
                    }

                    // 5. SYSTEM HARDWARE RESOURCES (CPU, RAM, DISK)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: dashboardWindow.showProcessList ? 280 : 100
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

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "󰍛 System Telemetry"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.bold: true
                                    font.pixelSize: 11
                                    color: Theme.fg1
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: dashboardWindow.showProcessList ? "󰅃 (collapse)" : "󰅀 (inspect memory)"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    color: dashboardWindow.showProcessList ? Theme.teal : Theme.silver
                                }
                            }

                            // CPU Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text { text: "CPU"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Theme.silver; Layout.preferredWidth: 32 }
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
                                Text { text: dashboardWindow.hwCpu + "%"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; color: Theme.accent; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
                            }

                            // RAM Row (Clickable to inspect top processes)
                            Rectangle {
                                Layout.fillWidth: true
                                height: 20
                                radius: 4
                                color: ramClickArea.containsMouse ? Theme.bg2 : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 8
                                    Text { text: "RAM"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Theme.silver; Layout.preferredWidth: 32 }
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
                                    Text { text: dashboardWindow.hwRamStr; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true; color: Theme.teal; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignRight }
                                }

                                MouseArea {
                                    id: ramClickArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dashboardWindow.showProcessList = !dashboardWindow.showProcessList
                                }
                            }

                            // Disk Storage Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text { text: "Disk"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Theme.silver; Layout.preferredWidth: 32 }
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
                                Text { text: dashboardWindow.hwDiskStr; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true; color: Theme.purple; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignRight }
                            }

                            // Expanded Process Inspector Section
                            ColumnLayout {
                                visible: dashboardWindow.showProcessList
                                Layout.fillWidth: true
                                spacing: 4

                                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.bg3 }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Top Memory Consumers"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; color: Theme.teal; Layout.fillWidth: true }
                                    Text { text: "Click 󰅖 to kill"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; color: Theme.silver }
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

                                            Text { text: String(index + 1) + "."; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: Theme.silver }
                                            Text { text: modelData.name; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; color: Theme.fg0; elide: Text.ElideRight; Layout.fillWidth: true }
                                            Text { text: modelData.mem; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true; color: Theme.teal }

                                            Rectangle {
                                                width: 16
                                                height: 16
                                                radius: 3
                                                color: killMouse.containsMouse ? Theme.red : Theme.bg2
                                                Text { anchors.centerIn: parent; text: "󰅖"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: killMouse.containsMouse ? Theme.bg0 : Theme.silver }
                                                MouseArea {
                                                    id: killMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        dashboardWindow.runDetached("kill -9 " + String(modelData.pid))
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

                    // 6. SAFE POWER ACTIONS (With Confirmation Dialog)
                    Item {
                        Layout.fillWidth: true
                        height: 40

                        // Normal Power Buttons Row
                        RowLayout {
                            anchors.fill: parent
                            spacing: 8
                            visible: dashboardWindow.pendingPowerAction === ""

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
                                    Text { text: "󰒲"; font.family: "JetBrainsMono Nerd Font"; color: Theme.secondary; font.pixelSize: 13 }
                                    Text { text: "Sleep"; font.family: "JetBrainsMono Nerd Font"; color: Theme.fg1; font.pixelSize: 10; font.bold: true }
                                }
                                MouseArea {
                                    id: suspMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        dashboardWindow.close()
                                        dashboardWindow.runDetached("systemctl suspend")
                                    }
                                }
                            }

                            // Restart (prompts confirmation)
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
                                    Text { text: "󰜉"; font.family: "JetBrainsMono Nerd Font"; color: Theme.tertiary; font.pixelSize: 13 }
                                    Text { text: "Restart"; font.family: "JetBrainsMono Nerd Font"; color: Theme.fg1; font.pixelSize: 10; font.bold: true }
                                }
                                MouseArea {
                                    id: rebMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dashboardWindow.pendingPowerAction = "reboot"
                                }
                            }

                            // Power Off (prompts confirmation)
                            Rectangle {
                                Layout.fillWidth: true
                                height: 38
                                radius: 6
                                color: offMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.2) : Theme.bg1
                                border.color: offMouse.containsMouse ? Theme.red : Theme.bg3
                                border.width: 1

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "󰐥"; font.family: "JetBrainsMono Nerd Font"; color: Theme.red; font.pixelSize: 13 }
                                    Text { text: "Power Off"; font.family: "JetBrainsMono Nerd Font"; color: Theme.fg1; font.pixelSize: 10; font.bold: true }
                                }
                                MouseArea {
                                    id: offMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dashboardWindow.pendingPowerAction = "poweroff"
                                }
                            }
                        }

                        // Inline Confirmation Modal (Prevents accidental shutdowns)
                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: Theme.bg2
                            border.color: Theme.red
                            border.width: 1
                            visible: dashboardWindow.pendingPowerAction !== ""

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8

                                Text {
                                    text: dashboardWindow.pendingPowerAction === "reboot" ? "󰜉 Restart PC?" : "󰐥 Power Off PC?"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.bold: true
                                    font.pixelSize: 11
                                    color: Theme.fg0
                                    Layout.fillWidth: true
                                    anchors.leftMargin: 4
                                }

                                // Cancel
                                Rectangle {
                                    width: 60
                                    height: 26
                                    radius: 4
                                    color: cancelMouse.containsMouse ? Theme.bg3 : Theme.bg1
                                    border.color: Theme.bg3
                                    border.width: 1
                                    Text { anchors.centerIn: parent; text: "Cancel"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Theme.silver }
                                    MouseArea {
                                        id: cancelMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: dashboardWindow.pendingPowerAction = ""
                                    }
                                }

                                // Confirm
                                Rectangle {
                                    width: 65
                                    height: 26
                                    radius: 4
                                    color: Theme.red
                                    Text { anchors.centerIn: parent; text: "Confirm"; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 10; color: Theme.bg0 }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let act = dashboardWindow.pendingPowerAction
                                            dashboardWindow.close()
                                            dashboardWindow.runDetached("systemctl " + act)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ================= NOTIFICATIONS VIEW =================
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
                        color: NotificationManager.dnd ? Theme.red : (notifDndBtn.containsMouse ? Theme.bg3 : Theme.bg2)
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
                            id: notifDndBtn
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
                        color: notifClearBtn.containsMouse ? Theme.bg3 : Theme.bg2
                        border.color: notifClearBtn.containsMouse ? Theme.red : Theme.bg3
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "󰅖"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: notifClearBtn.containsMouse ? Theme.red : Theme.gray
                            }
                            Text {
                                text: "Clear All"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: notifClearBtn.containsMouse ? Theme.red : Theme.fg1
                            }
                        }

                        MouseArea {
                            id: notifClearBtn
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
                            text: "You are all caught up!"
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
                                    font.pixelSize: 9
                                    color: Theme.gray
                                }

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 3
                                    color: notifDismissBtn.containsMouse ? Theme.red : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        color: notifDismissBtn.containsMouse ? Theme.bg0 : Theme.silver
                                    }

                                    MouseArea {
                                        id: notifDismissBtn
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotificationManager.removeNotification(modelData.id)
                                    }
                                }
                            }

                            // Notification title
                            Text {
                                visible: modelData.summary.length > 0
                                text: modelData.summary
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                font.pixelSize: 11
                                color: Theme.fg0
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }

                            // Notification body
                            Text {
                                visible: modelData.body.length > 0
                                text: modelData.body
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: Theme.fg2
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }

                            // Action buttons
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                visible: modelData.actions && modelData.actions.length > 0

                                Repeater {
                                    model: modelData.actions

                                    Rectangle {
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
        }
    }
}
