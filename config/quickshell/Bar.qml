import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
    id: barWindow

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 6
        left: 8
        right: 8
    }

    implicitHeight: 36
    color: "transparent"

    signal dashboardToggleRequested()
    signal launcherToggleRequested()
    signal wallpaperToggleRequested()
    signal calendarToggleRequested()

    // Real-time Clock & Date
    property string timeStr: Qt.formatTime(new Date(), "hh:mm AP")
    property string dateStr: Qt.formatDate(new Date(), "ddd, MMM d")

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let d = new Date()
            barWindow.timeStr = Qt.formatTime(d, "hh:mm AP")
            barWindow.dateStr = Qt.formatDate(d, "ddd, MMM d")
        }
    }

    // Command runner helper
    Process {
        id: cmdRunner
        property var cmd: []
        command: cmd
    }

    function runCmd(c) {
        cmdRunner.command = c
        cmdRunner.running = true
    }

    // ================= SENSORS & SYSTEM MONITORS =================

    // 1. Audio Output Volume & Mute
    property string volumeLevel: "50%"
    property bool isMuted: false
    Process {
        id: volReader
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{vol=int($2*100); if ($3==\"[MUTED]\") print vol\"% MUTED\"; else print vol\"%\"}'"]
        stdout: SplitParser {
            onRead: data => {
                let s = data.trim()
                if (s.length > 0) {
                    barWindow.isMuted = s.includes("MUTED")
                    barWindow.volumeLevel = s.replace(" MUTED", "")
                }
            }
        }
    }

    // 2. Microphone Mute State
    property bool isMicMuted: false
    Process {
        id: micReader
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q '\\[MUTED\\]' && echo 'MUTED' || echo 'ON'"]
        stdout: SplitParser {
            onRead: data => {
                barWindow.isMicMuted = data.trim() === "MUTED"
            }
        }
    }

    // 3. Display Brightness
    property string brightLevel: "75%"
    Process {
        id: briReader
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | awk -F, '{print $4}'"]
        stdout: SplitParser {
            onRead: data => {
                let s = data.trim()
                if (s.length > 0) barWindow.brightLevel = s
            }
        }
    }

    // 4. Laptop Battery & Charging State
    property int batteryPct: 100
    property string batteryState: "fully-charged"
    property string batteryIcon: "󰁹"
    Process {
        id: batReader
        command: ["sh", "-c", "upower -i /org/freedesktop/UPower/devices/battery_BAT1 2>/dev/null | awk '/percentage:/ {pct=$2} /state:/ {st=$2} END {if (pct) print pct, st; else print \"100% fully-charged\"}'"]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(" ")
                if (parts.length >= 1) {
                    let p = parseInt(parts[0].replace("%", "")) || 100
                    let st = parts[1] ?? "discharging"
                    barWindow.batteryPct = p
                    barWindow.batteryState = st

                    let isCharging = st === "charging" || (st === "fully-charged" && p >= 98)
                    if (isCharging) {
                        barWindow.batteryIcon = "󰂄"
                    } else {
                        if (p >= 90) barWindow.batteryIcon = "󰁹"
                        else if (p >= 80) barWindow.batteryIcon = "󰂂"
                        else if (p >= 70) barWindow.batteryIcon = "󰂁"
                        else if (p >= 60) barWindow.batteryIcon = "󰂀"
                        else if (p >= 50) barWindow.batteryIcon = "󰁿"
                        else if (p >= 40) barWindow.batteryIcon = "󰁾"
                        else if (p >= 30) barWindow.batteryIcon = "󰁽"
                        else if (p >= 20) barWindow.batteryIcon = "󰁼"
                        else barWindow.batteryIcon = "󰁺"
                    }
                }
            }
        }
    }

    // 5. Network & WiFi State
    property string netType: "wifi"
    property string netSsid: "Online"
    property string netIcon: "󰤨"
    Process {
        id: netReader
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION dev 2>/dev/null | grep -E '^wifi:connected|^ethernet:connected' | head -n 1"]
        stdout: SplitParser {
            onRead: data => {
                let line = data.trim()
                if (line.length > 0) {
                    let parts = line.split(":")
                    barWindow.netType = parts[0]
                    let connName = parts[2] ?? "Connected"
                    // Elide long SSIDs
                    barWindow.netSsid = connName.length > 14 ? connName.substring(0, 12) + ".." : connName
                    barWindow.netIcon = parts[0] === "ethernet" ? "󰈀" : "󰤨"
                } else {
                    barWindow.netType = "none"
                    barWindow.netSsid = "Disconnected"
                    barWindow.netIcon = "󰤭"
                }
            }
        }
    }

    // 6. Blue Light / Night Light State
    property string nightLightState: "off"
    property string nightLightLabel: "Off"
    property bool nightLightActive: false

    Process {
        id: nightLightReader
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/bluelight.sh", "status"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let d = JSON.parse(data)
                    barWindow.nightLightState = d.state ?? "off"
                    barWindow.nightLightLabel = d.label ?? "Off"
                    barWindow.nightLightActive = d.active ?? false
                } catch(e) {}
            }
        }
    }

    Process {
        id: nightLightToggler
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/bluelight.sh", "toggle"]
        onExited: nightLightReader.running = true
    }

    function toggleNightLight() {
        nightLightToggler.running = true
    }

    // Polling interval for sensors
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            volReader.running = true
            micReader.running = true
            briReader.running = true
            batReader.running = true
            netReader.running = true
            nightLightReader.running = true
        }
    }

    function adjustVolume(up) {
        let delta = up ? "5%+" : "5%-"
        runCmd(["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", delta])
        volReader.running = true
    }

    function toggleMute() {
        runCmd(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        volReader.running = true
    }

    function toggleMicMute() {
        runCmd(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
        micReader.running = true
    }

    function adjustBrightness(up) {
        let delta = up ? "5%+" : "5%-"
        runCmd(["brightnessctl", "set", delta])
        briReader.running = true
    }

    // Main Floating Island Bar
    RowLayout {
        anchors.fill: parent
        spacing: 8

        // ================= LEFT: App Launcher & Workspaces =================
        RowLayout {
            spacing: 6

            // Launcher Pill Button
            Rectangle {
                width: 36
                height: 34
                radius: 6
                color: launcherMouse.containsMouse ? Theme.bg2 : Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.88)
                border.color: launcherMouse.containsMouse ? Theme.accent : Theme.bg3
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰣇"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: launcherMouse.containsMouse ? Theme.accent : Theme.fg0
                }

                MouseArea {
                    id: launcherMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.launcherToggleRequested()
                }
            }

            // Workspaces Pill Container
            Rectangle {
                height: 34
                implicitWidth: wsRow.implicitWidth + 12
                radius: 6
                color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.88)
                border.color: Theme.bg3
                border.width: 1

                Row {
                    id: wsRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: [1, 2, 3, 4, 5]
                        Rectangle {
                            property bool isFocused: Hyprland.focusedMonitor &&
                                                     Hyprland.focusedMonitor.activeWorkspace &&
                                                     Hyprland.focusedMonitor.activeWorkspace.id === modelData

                            width: isFocused ? 28 : 22
                            height: 24
                            radius: 4
                            color: isFocused ? Theme.accent : (wsMouse.containsMouse ? Theme.bg3 : Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.5))

                            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.bold: isFocused
                                color: isFocused ? Theme.bg0 : (wsMouse.containsMouse ? Theme.fg0 : Theme.gray)
                            }

                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: barWindow.runCmd(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + modelData + " })"])
                            }
                        }
                    }
                }
            }

            // Night Light / Blue Light Filter Pill (Beside Workspaces)
            Rectangle {
                height: 34
                implicitWidth: nlRow.implicitWidth + 16
                radius: 6
                color: barWindow.nightLightActive
                       ? Qt.rgba(Theme.yellow.r, Theme.yellow.g, Theme.yellow.b, 0.2)
                       : (nlMouse.containsMouse ? Theme.bg2 : Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.88))
                border.color: barWindow.nightLightActive
                              ? Theme.yellow
                              : (nlMouse.containsMouse ? Theme.accent : Theme.bg3)
                border.width: 1

                Row {
                    id: nlRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰖔"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: barWindow.nightLightActive ? Theme.yellow : Theme.gray
                    }

                    Text {
                        text: barWindow.nightLightLabel
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: barWindow.nightLightActive
                        color: barWindow.nightLightActive ? Theme.yellow : Theme.fg1
                    }
                }

                MouseArea {
                    id: nlMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.toggleNightLight()
                }
            }
        }

        Item { Layout.fillWidth: true }

        // ================= CENTER: Clock & Date Pill =================
        Rectangle {
            id: clockPill
            height: 34
            implicitWidth: clockRow.implicitWidth + 24
            radius: 6
            color: clockMouse.containsMouse ? Theme.bg2 : Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.88)
            border.color: clockMouse.containsMouse ? Theme.accent : Theme.bg3
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            Row {
                id: clockRow
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "󰥔 " + barWindow.timeStr
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.fg0
                }

                Rectangle {
                    width: 3
                    height: 3
                    radius: 1.5
                    color: Theme.gray
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "󰸗 " + barWindow.dateStr
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: Theme.silver
                }
            }

            MouseArea {
                id: clockMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: barWindow.calendarToggleRequested()
            }
        }

        Item { Layout.fillWidth: true }

        // ================= RIGHT: System Status & Tools =================
        RowLayout {
            spacing: 6

            // Mic Muted Pill (Only visible when mic is muted for privacy)
            Rectangle {
                visible: barWindow.isMicMuted
                height: 34
                implicitWidth: micRow.implicitWidth + 12
                radius: 6
                color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.2)
                border.color: Theme.red
                border.width: 1

                Row {
                    id: micRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "󰍭"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: Theme.red }
                    Text { text: "MUTED"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; color: Theme.red }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.toggleMicMute()
                }
            }

            // Network / WiFi Pill
            Rectangle {
                height: 34
                implicitWidth: netRow.implicitWidth + 16
                radius: 6
                color: netMouse.containsMouse ? Theme.bg2 : Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.88)
                border.color: netMouse.containsMouse ? Theme.accent : Theme.bg3
                border.width: 1

                Row {
                    id: netRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: barWindow.netIcon
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: barWindow.netType === "none" ? Theme.gray : Theme.accent
                    }

                    Text {
                        text: barWindow.netSsid
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.fg1
                    }
                }

                MouseArea {
                    id: netMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.dashboardToggleRequested()
                }
            }

            // Battery Pill
            Rectangle {
                height: 34
                implicitWidth: batRow.implicitWidth + 16
                radius: 6
                color: batMouse.containsMouse ? Theme.bg2 : Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.88)
                border.color: (barWindow.batteryPct <= 20 && barWindow.batteryState !== "charging")
                              ? Theme.red
                              : (batMouse.containsMouse ? Theme.accent : Theme.bg3)
                border.width: 1

                Row {
                    id: batRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: barWindow.batteryIcon
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: (barWindow.batteryPct <= 20 && barWindow.batteryState !== "charging")
                               ? Theme.red
                               : Theme.accent
                    }

                    Text {
                        text: barWindow.batteryPct + "%"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        color: (barWindow.batteryPct <= 20 && barWindow.batteryState !== "charging")
                               ? Theme.red
                               : Theme.fg1
                    }
                }

                MouseArea {
                    id: batMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.dashboardToggleRequested()
                }
            }

            // Volume Pill
            Rectangle {
                height: 34
                implicitWidth: volRow.implicitWidth + 16
                radius: 6
                color: volMouse.containsMouse ? Theme.bg2 : Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.88)
                border.color: volMouse.containsMouse ? Theme.accent : Theme.bg3
                border.width: 1

                Row {
                    id: volRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: barWindow.isMuted ? "󰖁" : "󰕾"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: barWindow.isMuted ? Theme.red : Theme.accent
                    }

                    Text {
                        text: barWindow.volumeLevel
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.fg1
                    }
                }

                MouseArea {
                    id: volMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.toggleMute()
                    onWheel: wheel => {
                        barWindow.adjustVolume(wheel.angleDelta.y > 0)
                    }
                }
            }

            // Brightness Pill
            Rectangle {
                height: 34
                implicitWidth: briRow.implicitWidth + 16
                radius: 6
                color: briMouse.containsMouse ? Theme.bg2 : Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.88)
                border.color: briMouse.containsMouse ? Theme.accent : Theme.bg3
                border.width: 1

                Row {
                    id: briRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰃠"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: Theme.accent
                    }

                    Text {
                        text: barWindow.brightLevel
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.fg1
                    }
                }

                MouseArea {
                    id: briMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onWheel: wheel => {
                        barWindow.adjustBrightness(wheel.angleDelta.y > 0)
                    }
                }
            }

            // Wallpaper Picker Trigger
            Rectangle {
                width: 36
                height: 34
                radius: 6
                color: wallBtnMouse.containsMouse ? Theme.bg2 : Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.88)
                border.color: wallBtnMouse.containsMouse ? Theme.accent : Theme.bg3
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰸉"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: wallBtnMouse.containsMouse ? Theme.accent : Theme.fg0
                }

                MouseArea {
                    id: wallBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.wallpaperToggleRequested()
                }
            }

            // Notification Bell / Indicator Trigger
            Rectangle {
                width: notifBadge.visible ? 46 : 36
                height: 34
                radius: 6
                color: notifBtnMouse.containsMouse ? Theme.bg2 : Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.88)
                border.color: notifBtnMouse.containsMouse ? Theme.accent : (NotificationManager.dnd ? Theme.red : Theme.bg3)
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: NotificationManager.dnd ? "󰂛" : (NotificationManager.unreadCount > 0 ? "󰂞" : "󰂚")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: NotificationManager.dnd ? Theme.red : (NotificationManager.unreadCount > 0 ? Theme.accent : Theme.fg0)
                    }

                    Rectangle {
                        id: notifBadge
                        visible: NotificationManager.unreadCount > 0
                        width: Math.max(14, badgeText.implicitWidth + 6)
                        height: 14
                        radius: 7
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: NotificationManager.unreadCount > 99 ? "99+" : NotificationManager.unreadCount
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.bg0
                        }
                    }
                }

                MouseArea {
                    id: notifBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            NotificationManager.toggleDnd()
                        } else {
                            barWindow.dashboardToggleRequested()
                        }
                    }
                }
            }

            // Control Center Trigger
            Rectangle {
                width: 36
                height: 34
                radius: 6
                color: dashBtnMouse.containsMouse ? Theme.bg2 : Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.88)
                border.color: dashBtnMouse.containsMouse ? Theme.accent : Theme.bg3
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰍜"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: dashBtnMouse.containsMouse ? Theme.accent : Theme.fg0
                }

                MouseArea {
                    id: dashBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.dashboardToggleRequested()
                }
            }
        }
    }
}
