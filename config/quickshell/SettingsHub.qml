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

    // Tab state: 0 = Aesthetics & Physics, 1 = Processes & Tasks
    property int currentTab: 0

    function setTab(idx) {
        settingsWindow.currentTab = idx
        if (idx === 1) {
            hwStatsProc.running = true
        }
    }

    // Live tuning state (initialized with rice defaults)
    property int gapsIn: 3
    property int gapsOut: 6
    property int rounding: 6
    property int borderSize: 2
    property string animProfile: "smooth"
    property string activeSurface: "material"

    // Telemetry & Process state
    property int hwCpu: 0
    property int hwRam: 0
    property string hwRamStr: "0G / 0G"
    property int hwDisk: 0
    property string hwDiskStr: "0G / 0G"
    property var topProcs: []

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

    // Hardware resources & top processes
    Process {
        id: hwStatsProc
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/hw-stats.py"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let d = JSON.parse(data)
                    settingsWindow.hwCpu = d.cpu_pct ?? 0
                    settingsWindow.hwRam = d.ram_pct ?? 0
                    settingsWindow.hwRamStr = d.ram_str ?? "0G / 0G"
                    settingsWindow.hwDisk = d.disk_pct ?? 0
                    settingsWindow.hwDiskStr = d.disk_str ?? "0G / 0G"
                    settingsWindow.topProcs = d.top_procs ?? []
                } catch (e) {}
            }
        }
    }

    // Process polling timer when Processes tab is open
    Timer {
        id: statsTimer
        interval: 2000
        running: settingsWindow.visible && settingsWindow.currentTab === 1
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            hwStatsProc.running = true
        }
    }

    onVisibleChanged: {
        if (visible && currentTab === 1) {
            hwStatsProc.running = true
        }
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
        width: 580
        height: Math.min(680, cardLayout.implicitHeight + 40)
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
                        text: settingsWindow.currentTab === 0 ? "󰒓" : "󰍛"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: Theme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "System & Desktop Hub"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 14
                        color: Theme.fg0
                    }
                    Text {
                        text: settingsWindow.currentTab === 0 ? "Real-time desktop aesthetic & physics tuning" : "Hardware telemetry & process management"
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

            // Segmented Tab Switcher
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 8
                color: Theme.bg1
                border.color: Theme.bg2
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    // Tab 0: Aesthetics & Physics
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 6
                        color: settingsWindow.currentTab === 0 ? Theme.accent : "transparent"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰒓"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                color: settingsWindow.currentTab === 0 ? Theme.bg0 : Theme.silver
                            }
                            Text {
                                text: "Aesthetics & Physics"
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                font.pixelSize: 11
                                color: settingsWindow.currentTab === 0 ? Theme.bg0 : Theme.fg1
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsWindow.setTab(0)
                        }
                    }

                    // Tab 1: Processes & Tasks
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 6
                        color: settingsWindow.currentTab === 1 ? Theme.accent : "transparent"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰍛"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                color: settingsWindow.currentTab === 1 ? Theme.bg0 : Theme.silver
                            }
                            Text {
                                text: "Processes & Tasks"
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                font.pixelSize: 11
                                color: settingsWindow.currentTab === 1 ? Theme.bg0 : Theme.fg1
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsWindow.setTab(1)
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.bg2
            }

            // ================= TAB 0: AESTHETICS & PHYSICS =================
            ColumnLayout {
                visible: settingsWindow.currentTab === 0
                Layout.fillWidth: true
                spacing: 14

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
            }

            // ================= TAB 1: PROCESSES & TASKS =================
            ColumnLayout {
                visible: settingsWindow.currentTab === 1
                Layout.fillWidth: true
                spacing: 12

                // Resource Overview Cards
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // CPU Metric
                    Rectangle {
                        Layout.fillWidth: true
                        height: 52
                        radius: 8
                        color: Theme.bg1
                        border.color: Theme.bg2
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "󰻠 CPU"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Theme.silver }
                                Item { Layout.fillWidth: true }
                                Text { text: settingsWindow.hwCpu + "%"; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 11; color: Theme.accent }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 4
                                radius: 2
                                color: Theme.bg2
                                Rectangle {
                                    width: parent.width * (Math.min(100, Math.max(0, settingsWindow.hwCpu)) / 100.0)
                                    height: parent.height
                                    radius: 2
                                    color: Theme.accent
                                }
                            }
                        }
                    }

                    // RAM Metric
                    Rectangle {
                        Layout.fillWidth: true
                        height: 52
                        radius: 8
                        color: Theme.bg1
                        border.color: Theme.bg2
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "󰍛 RAM"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Theme.silver }
                                Item { Layout.fillWidth: true }
                                Text { text: settingsWindow.hwRamStr; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 10; color: Theme.teal }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 4
                                radius: 2
                                color: Theme.bg2
                                Rectangle {
                                    width: parent.width * (Math.min(100, Math.max(0, settingsWindow.hwRam)) / 100.0)
                                    height: parent.height
                                    radius: 2
                                    color: Theme.teal
                                }
                            }
                        }
                    }

                    // Disk Metric
                    Rectangle {
                        Layout.fillWidth: true
                        height: 52
                        radius: 8
                        color: Theme.bg1
                        border.color: Theme.bg2
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "󰋊 Disk"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Theme.silver }
                                Item { Layout.fillWidth: true }
                                Text { text: settingsWindow.hwDiskStr; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 10; color: Theme.purple }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 4
                                radius: 2
                                color: Theme.bg2
                                Rectangle {
                                    width: parent.width * (Math.min(100, Math.max(0, settingsWindow.hwDisk)) / 100.0)
                                    height: parent.height
                                    radius: 2
                                    color: Theme.purple
                                }
                            }
                        }
                    }
                }

                // Process List Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Active Tasks (Ranked by Memory RSS)"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 11
                        color: Theme.fg0
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Click Kill to terminate task"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        color: Theme.silver
                    }
                }

                // Scrollable Process Table
                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 250
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: settingsWindow.topProcs

                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 6
                                color: procMouse.containsMouse ? Theme.bg2 : Theme.bg1
                                border.color: procMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : Theme.bg2
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    // Index
                                    Text {
                                        text: String(index + 1) + "."
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        color: Theme.silver
                                        Layout.preferredWidth: 20
                                    }

                                    // Name
                                    Text {
                                        text: modelData.name
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Theme.fg0
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    // PID
                                    Rectangle {
                                        height: 18
                                        radius: 4
                                        width: pidText.implicitWidth + 8
                                        color: Theme.bg0
                                        border.color: Theme.bg3
                                        border.width: 1
                                        Text {
                                            id: pidText
                                            anchors.centerIn: parent
                                            text: "PID " + modelData.pid
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 8
                                            color: Theme.silver
                                        }
                                    }

                                    // RAM % and RSS
                                    Text {
                                        text: modelData.mem
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.teal
                                        Layout.preferredWidth: 64
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    // Kill Action Button
                                    Rectangle {
                                        id: killBtn
                                        width: 52
                                        height: 22
                                        radius: 4
                                        color: killMouse.containsMouse ? Theme.red : Theme.bg2
                                        border.color: killMouse.containsMouse ? Theme.red : Theme.bg3
                                        border.width: 1

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 3
                                            Text {
                                                text: "󰅖"
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 10
                                                color: killMouse.containsMouse ? Theme.bg0 : Theme.red
                                            }
                                            Text {
                                                text: "Kill"
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.bold: true
                                                font.pixelSize: 10
                                                color: killMouse.containsMouse ? Theme.bg0 : Theme.fg1
                                            }
                                        }

                                        MouseArea {
                                            id: killMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                let targetPid = String(modelData.pid)
                                                let targetName = String(modelData.name)

                                                // Optimistically remove from list
                                                let updated = []
                                                for (let i = 0; i < settingsWindow.topProcs.length; i++) {
                                                    if (String(settingsWindow.topProcs[i].pid) !== targetPid) {
                                                        updated.push(settingsWindow.topProcs[i])
                                                    }
                                                }
                                                settingsWindow.topProcs = updated

                                                // Force kill and notify
                                                settingsWindow.runDetached("kill -9 " + targetPid + " && notify-send -a 'System Hub' -i 'process-stop' 'Process Terminated' 'Killed " + targetName + " (PID " + targetPid + ")'")
                                                hwStatsProc.running = true
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: procMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                }
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

                // Left Action Button
                Rectangle {
                    height: 34
                    Layout.preferredWidth: settingsWindow.currentTab === 0 ? 150 : 130
                    radius: 8
                    color: leftActionMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: Theme.bg3
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: settingsWindow.currentTab === 0 ? "󰦛" : "󰑐"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            color: Theme.silver
                        }
                        Text {
                            text: settingsWindow.currentTab === 0 ? "Reset Defaults" : "Refresh"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: Theme.fg1
                        }
                    }

                    MouseArea {
                        id: leftActionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (settingsWindow.currentTab === 0) {
                                settingsWindow.resetDefaults()
                            } else {
                                hwStatsProc.running = true
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    height: 34
                    Layout.preferredWidth: 90
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
