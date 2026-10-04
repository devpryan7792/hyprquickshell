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

    // Tab state: 0 = Rice Studio, 1 = Processes & Telemetry
    property int currentTab: 0

    function setTab(idx) {
        settingsWindow.currentTab = idx
        if (idx === 1) {
            hwStatsProc.running = true
        }
    }

    // Live tuning state (initialized with rice defaults)
    // Gaps Out (Window Margins to screen edges)
    property int gapsOut: 6
    property bool perSideGapsOut: false
    property int gapsOutTop: 6
    property int gapsOutRight: 6
    property int gapsOutBottom: 6
    property int gapsOutLeft: 6

    // Gaps In (Window Padding / Gaps between windows)
    property int gapsIn: 3
    property bool perSideGapsIn: false
    property int gapsInTop: 3
    property int gapsInRight: 3
    property int gapsInBottom: 3
    property int gapsInLeft: 3

    // Geometry & Borders
    property int rounding: 6
    property int borderSize: 1

    // Effects, Blur & Opacity
    property bool blurEnabled: true
    property int blurSize: 6
    property int blurPasses: 2
    property real activeOpacity: 1.0
    property real inactiveOpacity: 0.95

    // Animation & Surface
    property string animProfile: "smooth"
    property string activeSurface: "material"

    // Collapsible accordion section toggles (start with Gaps open, rest collapsed)
    property bool sectionMarginsOpen: true
    property bool sectionPaddingOpen: false
    property bool sectionGeometryOpen: false
    property bool sectionEffectsOpen: false
    property bool sectionAnimOpen: false
    property bool sectionSurfaceOpen: false

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

    // Process to read current surface mode
    Process {
        id: readSurfaceProc
        command: ["cat", Quickshell.env("HOME") + "/.cache/hyprdots-surface-mode"]
        stdout: SplitParser {
            onRead: data => {
                let s = data.trim()
                if (s.length > 0) {
                    settingsWindow.activeSurface = s
                }
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
        if (visible) {
            readSurfaceProc.running = true
            if (currentTab === 1) {
                hwStatsProc.running = true
            }
        }
    }

    // Debounced live Hyprland evaluator
    Timer {
        id: liveEvalTimer
        interval: 30
        repeat: false
        onTriggered: {
            let gapsOutVal = settingsWindow.perSideGapsOut
                ? "{ top = " + settingsWindow.gapsOutTop + ", right = " + settingsWindow.gapsOutRight + ", bottom = " + settingsWindow.gapsOutBottom + ", left = " + settingsWindow.gapsOutLeft + " }"
                : settingsWindow.gapsOut;

            let gapsInVal = settingsWindow.perSideGapsIn
                ? "{ top = " + settingsWindow.gapsInTop + ", right = " + settingsWindow.gapsInRight + ", bottom = " + settingsWindow.gapsInBottom + ", left = " + settingsWindow.gapsInLeft + " }"
                : settingsWindow.gapsIn;

            let evalCode = "hl.config({ general = { " +
                           "gaps_in = " + gapsInVal + ", " +
                           "gaps_out = " + gapsOutVal + ", " +
                           "border_size = " + settingsWindow.borderSize + " }, " +
                           "decoration = { " +
                           "rounding = " + settingsWindow.rounding + ", " +
                           "active_opacity = " + Number(settingsWindow.activeOpacity).toFixed(2) + ", " +
                           "inactive_opacity = " + Number(settingsWindow.inactiveOpacity).toFixed(2) + ", " +
                           "blur = { enabled = " + (settingsWindow.blurEnabled ? "true" : "false") + ", size = " + settingsWindow.blurSize + ", passes = " + settingsWindow.blurPasses + " } } })"

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
        settingsWindow.perSideGapsOut = false
        settingsWindow.gapsOutTop = 6
        settingsWindow.gapsOutRight = 6
        settingsWindow.gapsOutBottom = 6
        settingsWindow.gapsOutLeft = 6
        settingsWindow.perSideGapsIn = false
        settingsWindow.gapsInTop = 3
        settingsWindow.gapsInRight = 3
        settingsWindow.gapsInBottom = 3
        settingsWindow.gapsInLeft = 3
        settingsWindow.rounding = 6
        settingsWindow.borderSize = 1
        settingsWindow.blurEnabled = true
        settingsWindow.blurSize = 6
        settingsWindow.blurPasses = 2
        settingsWindow.activeOpacity = 1.0
        settingsWindow.inactiveOpacity = 0.95
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
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: settingsWindow.close()
        }
    }

    // Main Studio Card Modal Container (Sleek 500x680, 2px border, non-book-like)
    Rectangle {
        id: mainCard
        anchors.centerIn: parent
        width: 500
        height: 680
        radius: 12
        color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.98)
        border.color: Theme.accent
        border.width: 2
        clip: true

        scale: settingsWindow.visible ? 1.0 : 0.96
        opacity: settingsWindow.visible ? 1.0 : 0.0
        Behavior on scale {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // 1. Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 32
                    height: 32
                    radius: 8
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                    border.color: Theme.accent
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: settingsWindow.currentTab === 0 ? "󰒓" : "󰍛"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: Theme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: "Rice Studio"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 13
                        color: Theme.fg0
                    }
                    Text {
                        text: settingsWindow.currentTab === 0 ? "Live CSS Margins, Blur, Corners & FX" : "Hardware telemetry & process management"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        color: Theme.silver
                    }
                }

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
                        onClicked: settingsWindow.close()
                    }
                }
            }

            // 2. Segmented Tab Switcher
            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 6
                color: Theme.bg1
                border.color: Theme.bg2
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 2
                    spacing: 4

                    // Tab 0: Rice Studio
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: settingsWindow.currentTab === 0 ? Theme.accent : "transparent"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰒓"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: settingsWindow.currentTab === 0 ? Theme.bg0 : Theme.silver
                            }
                            Text {
                                text: "Rice Studio"
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                font.pixelSize: 10
                                color: settingsWindow.currentTab === 0 ? Theme.bg0 : Theme.fg1
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsWindow.setTab(0)
                        }
                    }

                    // Tab 1: Telemetry & Tasks
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: settingsWindow.currentTab === 1 ? Theme.accent : "transparent"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰍛"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: settingsWindow.currentTab === 1 ? Theme.bg0 : Theme.silver
                            }
                            Text {
                                text: "System Tasks"
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                font.pixelSize: 10
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

            // ================= TAB 0: RICE STUDIO (SCROLLABLE ACCORDION) =================
            ScrollView {
                visible: settingsWindow.currentTab === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                }

                ColumnLayout {
                    width: parent.width
                    spacing: 8

                    // ---------------- SECTION 1: SCREEN MARGINS (OUTER GAPS) ----------------
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: secMarginsCol.implicitHeight + 16
                        radius: 8
                        color: Theme.bg1
                        border.color: settingsWindow.sectionMarginsOpen ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Theme.bg2
                        border.width: 1

                        ColumnLayout {
                            id: secMarginsCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 8

                            // Header Clickable
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: 24

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 8

                                    Text {
                                        text: "󰖲"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: Theme.accent
                                    }

                                    Text {
                                        text: "Screen Margins (Outer Gaps)"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                        font.pixelSize: 11
                                        color: Theme.fg0
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        height: 18
                                        implicitWidth: marginBadgeText.implicitWidth + 8
                                        radius: 4
                                        color: Theme.bg2
                                        Text {
                                            id: marginBadgeText
                                            anchors.centerIn: parent
                                            text: settingsWindow.perSideGapsOut
                                                  ? (settingsWindow.gapsOutTop + "T " + settingsWindow.gapsOutRight + "R " + settingsWindow.gapsOutBottom + "B " + settingsWindow.gapsOutLeft + "L")
                                                  : (settingsWindow.gapsOut + " px")
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: Theme.accent
                                        }
                                    }

                                    Text {
                                        text: settingsWindow.sectionMarginsOpen ? "󰅃" : "󰅂"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        color: Theme.silver
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: settingsWindow.sectionMarginsOpen = !settingsWindow.sectionMarginsOpen
                                }
                            }

                            // Body
                            ColumnLayout {
                                visible: settingsWindow.sectionMarginsOpen
                                Layout.fillWidth: true
                                spacing: 8

                                // Per-side toggle switch
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 26
                                    radius: 6
                                    color: settingsWindow.perSideGapsOut ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : Theme.bg2
                                    border.color: settingsWindow.perSideGapsOut ? Theme.accent : Theme.bg3
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        Text {
                                            text: "Individual Sides (CSS: Top, Right, Bottom, Left)"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            color: settingsWindow.perSideGapsOut ? Theme.accent : Theme.silver
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: settingsWindow.perSideGapsOut ? "PER-SIDE ON" : "UNIFIED"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.bold: true
                                            font.pixelSize: 8
                                            color: settingsWindow.perSideGapsOut ? Theme.accent : Theme.silver
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            settingsWindow.perSideGapsOut = !settingsWindow.perSideGapsOut
                                            if (settingsWindow.perSideGapsOut) {
                                                settingsWindow.gapsOutTop = settingsWindow.gapsOut
                                                settingsWindow.gapsOutRight = settingsWindow.gapsOut
                                                settingsWindow.gapsOutBottom = settingsWindow.gapsOut
                                                settingsWindow.gapsOutLeft = settingsWindow.gapsOut
                                            }
                                            liveEvalTimer.restart()
                                        }
                                    }
                                }

                                // Master outer gap slider (when unified)
                                RowLayout {
                                    visible: !settingsWindow.perSideGapsOut
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text {
                                        text: "All Margins"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        color: Theme.fg1
                                        Layout.preferredWidth: 90
                                    }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 40
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
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.accent
                                        Layout.preferredWidth: 40
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                // 4 Individual sliders (when per-side active)
                                ColumnLayout {
                                    visible: settingsWindow.perSideGapsOut
                                    Layout.fillWidth: true
                                    spacing: 4

                                    // Top Margin
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Text { text: "Margin Top"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: Theme.fg1; Layout.preferredWidth: 90 }
                                        Slider {
                                            Layout.fillWidth: true; from: 0; to: 40; stepSize: 1; value: settingsWindow.gapsOutTop
                                            onMoved: { settingsWindow.gapsOutTop = Math.round(value); liveEvalTimer.restart() }
                                        }
                                        Text { text: settingsWindow.gapsOutTop + " px"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true; color: Theme.accent; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
                                    }

                                    // Right Margin
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Text { text: "Margin Right"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: Theme.fg1; Layout.preferredWidth: 90 }
                                        Slider {
                                            Layout.fillWidth: true; from: 0; to: 40; stepSize: 1; value: settingsWindow.gapsOutRight
                                            onMoved: { settingsWindow.gapsOutRight = Math.round(value); liveEvalTimer.restart() }
                                        }
                                        Text { text: settingsWindow.gapsOutRight + " px"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true; color: Theme.accent; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
                                    }

                                    // Bottom Margin
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Text { text: "Margin Bottom"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: Theme.fg1; Layout.preferredWidth: 90 }
                                        Slider {
                                            Layout.fillWidth: true; from: 0; to: 40; stepSize: 1; value: settingsWindow.gapsOutBottom
                                            onMoved: { settingsWindow.gapsOutBottom = Math.round(value); liveEvalTimer.restart() }
                                        }
                                        Text { text: settingsWindow.gapsOutBottom + " px"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true; color: Theme.accent; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
                                    }

                                    // Left Margin
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Text { text: "Margin Left"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: Theme.fg1; Layout.preferredWidth: 90 }
                                        Slider {
                                            Layout.fillWidth: true; from: 0; to: 40; stepSize: 1; value: settingsWindow.gapsOutLeft
                                            onMoved: { settingsWindow.gapsOutLeft = Math.round(value); liveEvalTimer.restart() }
                                        }
                                        Text { text: settingsWindow.gapsOutLeft + " px"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true; color: Theme.accent; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
                                    }
                                }
                            }
                        }
                    }

                    // ---------------- SECTION 2: WINDOW PADDING (INNER GAPS) ----------------
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: secPaddingCol.implicitHeight + 16
                        radius: 8
                        color: Theme.bg1
                        border.color: settingsWindow.sectionPaddingOpen ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Theme.bg2
                        border.width: 1

                        ColumnLayout {
                            id: secPaddingCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 8

                            // Header Clickable
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: 24

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 8

                                    Text {
                                        text: "󰝤"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: Theme.accent
                                    }

                                    Text {
                                        text: "Window Padding (Inner Gaps)"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                        font.pixelSize: 11
                                        color: Theme.fg0
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        height: 18
                                        implicitWidth: padBadgeText.implicitWidth + 8
                                        radius: 4
                                        color: Theme.bg2
                                        Text {
                                            id: padBadgeText
                                            anchors.centerIn: parent
                                            text: settingsWindow.perSideGapsIn
                                                  ? (settingsWindow.gapsInTop + "T " + settingsWindow.gapsInRight + "R " + settingsWindow.gapsInBottom + "B " + settingsWindow.gapsInLeft + "L")
                                                  : (settingsWindow.gapsIn + " px")
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: Theme.accent
                                        }
                                    }

                                    Text {
                                        text: settingsWindow.sectionPaddingOpen ? "󰅃" : "󰅂"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        color: Theme.silver
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: settingsWindow.sectionPaddingOpen = !settingsWindow.sectionPaddingOpen
                                }
                            }

                            // Body
                            ColumnLayout {
                                visible: settingsWindow.sectionPaddingOpen
                                Layout.fillWidth: true
                                spacing: 8

                                // Per-side toggle switch
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 26
                                    radius: 6
                                    color: settingsWindow.perSideGapsIn ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : Theme.bg2
                                    border.color: settingsWindow.perSideGapsIn ? Theme.accent : Theme.bg3
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        Text {
                                            text: "Individual Sides (CSS: Top, Right, Bottom, Left)"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            color: settingsWindow.perSideGapsIn ? Theme.accent : Theme.silver
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: settingsWindow.perSideGapsIn ? "PER-SIDE ON" : "UNIFIED"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.bold: true
                                            font.pixelSize: 8
                                            color: settingsWindow.perSideGapsIn ? Theme.accent : Theme.silver
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            settingsWindow.perSideGapsIn = !settingsWindow.perSideGapsIn
                                            if (settingsWindow.perSideGapsIn) {
                                                settingsWindow.gapsInTop = settingsWindow.gapsIn
                                                settingsWindow.gapsInRight = settingsWindow.gapsIn
                                                settingsWindow.gapsInBottom = settingsWindow.gapsIn
                                                settingsWindow.gapsInLeft = settingsWindow.gapsIn
                                            }
                                            liveEvalTimer.restart()
                                        }
                                    }
                                }

                                // Master inner gap slider (when unified)
                                RowLayout {
                                    visible: !settingsWindow.perSideGapsIn
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text {
                                        text: "All Windows"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        color: Theme.fg1
                                        Layout.preferredWidth: 90
                                    }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 30
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
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.accent
                                        Layout.preferredWidth: 40
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                // 4 Individual sliders (when per-side active)
                                ColumnLayout {
                                    visible: settingsWindow.perSideGapsIn
                                    Layout.fillWidth: true
                                    spacing: 4

                                    // Top Padding
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Text { text: "Padding Top"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: Theme.fg1; Layout.preferredWidth: 90 }
                                        Slider {
                                            Layout.fillWidth: true; from: 0; to: 30; stepSize: 1; value: settingsWindow.gapsInTop
                                            onMoved: { settingsWindow.gapsInTop = Math.round(value); liveEvalTimer.restart() }
                                        }
                                        Text { text: settingsWindow.gapsInTop + " px"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true; color: Theme.accent; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
                                    }

                                    // Right Padding
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Text { text: "Padding Right"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: Theme.fg1; Layout.preferredWidth: 90 }
                                        Slider {
                                            Layout.fillWidth: true; from: 0; to: 30; stepSize: 1; value: settingsWindow.gapsInRight
                                            onMoved: { settingsWindow.gapsInRight = Math.round(value); liveEvalTimer.restart() }
                                        }
                                        Text { text: settingsWindow.gapsInRight + " px"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true; color: Theme.accent; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
                                    }

                                    // Bottom Padding
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Text { text: "Padding Bottom"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: Theme.fg1; Layout.preferredWidth: 90 }
                                        Slider {
                                            Layout.fillWidth: true; from: 0; to: 30; stepSize: 1; value: settingsWindow.gapsInBottom
                                            onMoved: { settingsWindow.gapsInBottom = Math.round(value); liveEvalTimer.restart() }
                                        }
                                        Text { text: settingsWindow.gapsInBottom + " px"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true; color: Theme.accent; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
                                    }

                                    // Left Padding
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Text { text: "Padding Left"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: Theme.fg1; Layout.preferredWidth: 90 }
                                        Slider {
                                            Layout.fillWidth: true; from: 0; to: 30; stepSize: 1; value: settingsWindow.gapsInLeft
                                            onMoved: { settingsWindow.gapsInLeft = Math.round(value); liveEvalTimer.restart() }
                                        }
                                        Text { text: settingsWindow.gapsInLeft + " px"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true; color: Theme.accent; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
                                    }
                                }
                            }
                        }
                    }

                    // ---------------- SECTION 3: CORNERS & BORDERS ----------------
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: secGeomCol.implicitHeight + 16
                        radius: 8
                        color: Theme.bg1
                        border.color: settingsWindow.sectionGeometryOpen ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Theme.bg2
                        border.width: 1

                        ColumnLayout {
                            id: secGeomCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 8

                            // Header Clickable
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: 24

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 8

                                    Text {
                                        text: "󰅂"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: Theme.accent
                                    }

                                    Text {
                                        text: "Corner Radius & Borders"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                        font.pixelSize: 11
                                        color: Theme.fg0
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        height: 18
                                        implicitWidth: geomBadgeText.implicitWidth + 8
                                        radius: 4
                                        color: Theme.bg2
                                        Text {
                                            id: geomBadgeText
                                            anchors.centerIn: parent
                                            text: settingsWindow.rounding + "px rad / " + settingsWindow.borderSize + "px border"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: Theme.accent
                                        }
                                    }

                                    Text {
                                        text: settingsWindow.sectionGeometryOpen ? "󰅃" : "󰅂"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        color: Theme.silver
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: settingsWindow.sectionGeometryOpen = !settingsWindow.sectionGeometryOpen
                                }
                            }

                            // Body
                            ColumnLayout {
                                visible: settingsWindow.sectionGeometryOpen
                                Layout.fillWidth: true
                                spacing: 8

                                // Corner Radius (Border Radius)
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text {
                                        text: "Border Radius"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        color: Theme.fg1
                                        Layout.preferredWidth: 90
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
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.accent
                                        Layout.preferredWidth: 40
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                // Border Width
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text {
                                        text: "Border Width"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        color: Theme.fg1
                                        Layout.preferredWidth: 90
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
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.accent
                                        Layout.preferredWidth: 40
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }

                    // ---------------- SECTION 4: BLUR, OPACITY & EFFECTS ----------------
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: secEffectsCol.implicitHeight + 16
                        radius: 8
                        color: Theme.bg1
                        border.color: settingsWindow.sectionEffectsOpen ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Theme.bg2
                        border.width: 1

                        ColumnLayout {
                            id: secEffectsCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 8

                            // Header Clickable
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: 24

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 8

                                    Text {
                                        text: "✨"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: Theme.accent
                                    }

                                    Text {
                                        text: "Blur, Opacity & FX"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                        font.pixelSize: 11
                                        color: Theme.fg0
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        height: 18
                                        implicitWidth: fxBadgeText.implicitWidth + 8
                                        radius: 4
                                        color: Theme.bg2
                                        Text {
                                            id: fxBadgeText
                                            anchors.centerIn: parent
                                            text: (settingsWindow.blurEnabled ? "Blur ON" : "Blur OFF") + " • " + Math.round(settingsWindow.activeOpacity * 100) + "%"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: Theme.accent
                                        }
                                    }

                                    Text {
                                        text: settingsWindow.sectionEffectsOpen ? "󰅃" : "󰅂"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        color: Theme.silver
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: settingsWindow.sectionEffectsOpen = !settingsWindow.sectionEffectsOpen
                                }
                            }

                            // Body
                            ColumnLayout {
                                visible: settingsWindow.sectionEffectsOpen
                                Layout.fillWidth: true
                                spacing: 8

                                // Blur Toggle Switch
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 26
                                    radius: 6
                                    color: settingsWindow.blurEnabled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : Theme.bg2
                                    border.color: settingsWindow.blurEnabled ? Theme.accent : Theme.bg3
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        Text {
                                            text: "Hardware Window Blur"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            color: settingsWindow.blurEnabled ? Theme.accent : Theme.silver
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: settingsWindow.blurEnabled ? "ENABLED" : "DISABLED"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.bold: true
                                            font.pixelSize: 8
                                            color: settingsWindow.blurEnabled ? Theme.accent : Theme.silver
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            settingsWindow.blurEnabled = !settingsWindow.blurEnabled
                                            liveEvalTimer.restart()
                                        }
                                    }
                                }

                                // Blur Size
                                RowLayout {
                                    visible: settingsWindow.blurEnabled
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text { text: "Blur Size"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Theme.fg1; Layout.preferredWidth: 90 }
                                    Slider {
                                        Layout.fillWidth: true; from: 1; to: 16; stepSize: 1; value: settingsWindow.blurSize
                                        onMoved: { settingsWindow.blurSize = Math.round(value); liveEvalTimer.restart() }
                                    }
                                    Text { text: settingsWindow.blurSize + " px"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; color: Theme.accent; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
                                }

                                // Blur Passes
                                RowLayout {
                                    visible: settingsWindow.blurEnabled
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text { text: "Blur Passes"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Theme.fg1; Layout.preferredWidth: 90 }
                                    Slider {
                                        Layout.fillWidth: true; from: 1; to: 5; stepSize: 1; value: settingsWindow.blurPasses
                                        onMoved: { settingsWindow.blurPasses = Math.round(value); liveEvalTimer.restart() }
                                    }
                                    Text { text: settingsWindow.blurPasses + " x"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; color: Theme.accent; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
                                }

                                // Active Opacity
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text { text: "Active Opacity"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Theme.fg1; Layout.preferredWidth: 90 }
                                    Slider {
                                        Layout.fillWidth: true; from: 0.50; to: 1.0; stepSize: 0.05; value: settingsWindow.activeOpacity
                                        onMoved: { settingsWindow.activeOpacity = Math.round(value * 100) / 100.0; liveEvalTimer.restart() }
                                    }
                                    Text { text: Math.round(settingsWindow.activeOpacity * 100) + " %"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; color: Theme.accent; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
                                }

                                // Inactive Opacity
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text { text: "Inactive Opacity"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Theme.fg1; Layout.preferredWidth: 90 }
                                    Slider {
                                        Layout.fillWidth: true; from: 0.50; to: 1.0; stepSize: 0.05; value: settingsWindow.inactiveOpacity
                                        onMoved: { settingsWindow.inactiveOpacity = Math.round(value * 100) / 100.0; liveEvalTimer.restart() }
                                    }
                                    Text { text: Math.round(settingsWindow.inactiveOpacity * 100) + " %"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; color: Theme.accent; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
                                }
                            }
                        }
                    }

                    // ---------------- SECTION 5: ANIMATION PROFILES ----------------
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: secAnimCol.implicitHeight + 16
                        radius: 8
                        color: Theme.bg1
                        border.color: settingsWindow.sectionAnimOpen ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Theme.bg2
                        border.width: 1

                        ColumnLayout {
                            id: secAnimCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 8

                            // Header Clickable
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: 24

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 8

                                    Text {
                                        text: "󰓅"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: Theme.accent
                                    }

                                    Text {
                                        text: "Animation Physics Profile"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                        font.pixelSize: 11
                                        color: Theme.fg0
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        height: 18
                                        implicitWidth: animBadgeText.implicitWidth + 8
                                        radius: 4
                                        color: Theme.bg2
                                        Text {
                                            id: animBadgeText
                                            anchors.centerIn: parent
                                            text: settingsWindow.animProfile.toUpperCase()
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: Theme.accent
                                        }
                                    }

                                    Text {
                                        text: settingsWindow.sectionAnimOpen ? "󰅃" : "󰅂"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        color: Theme.silver
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: settingsWindow.sectionAnimOpen = !settingsWindow.sectionAnimOpen
                                }
                            }

                            // Body
                            RowLayout {
                                visible: settingsWindow.sectionAnimOpen
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: [
                                        { id: "instant", label: "Instant", icon: "󰓅" },
                                        { id: "snappy",  label: "Snappy",  icon: "󰁨" },
                                        { id: "smooth",  label: "Smooth",  icon: "󰓅" },
                                        { id: "float",   label: "Float",   icon: "󰾕" }
                                    ]

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 34
                                        radius: 6
                                        readonly property bool isSelected: settingsWindow.animProfile === modelData.id
                                        color: isSelected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) : Theme.bg2
                                        border.color: isSelected ? Theme.accent : (pMouse.containsMouse ? Theme.accent : Theme.bg3)
                                        border.width: isSelected ? 1.5 : 1

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Text {
                                                text: modelData.icon
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 11
                                                color: parent.parent.isSelected ? Theme.accent : Theme.silver
                                            }
                                            Text {
                                                text: modelData.label
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.bold: true
                                                font.pixelSize: 9
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
                    }

                    // ---------------- SECTION 6: SURFACE GLASS & TONE ----------------
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: secSurfCol.implicitHeight + 16
                        radius: 8
                        color: Theme.bg1
                        border.color: settingsWindow.sectionSurfaceOpen ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Theme.bg2
                        border.width: 1

                        ColumnLayout {
                            id: secSurfCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 8

                            // Header Clickable
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: 24

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 8

                                    Text {
                                        text: "󰏘"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: Theme.accent
                                    }

                                    Text {
                                        text: "Surface Glass & Tone"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                        font.pixelSize: 11
                                        color: Theme.fg0
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        height: 18
                                        implicitWidth: surfBadgeText.implicitWidth + 8
                                        radius: 4
                                        color: Theme.bg2
                                        Text {
                                            id: surfBadgeText
                                            anchors.centerIn: parent
                                            text: settingsWindow.activeSurface.toUpperCase()
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: Theme.accent
                                        }
                                    }

                                    Text {
                                        text: settingsWindow.sectionSurfaceOpen ? "󰅃" : "󰅂"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        color: Theme.silver
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: settingsWindow.sectionSurfaceOpen = !settingsWindow.sectionSurfaceOpen
                                }
                            }

                            // Body
                            ColumnLayout {
                                visible: settingsWindow.sectionSurfaceOpen
                                Layout.fillWidth: true
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Repeater {
                                        model: [
                                            { id: "obsidian", name: "Obsidian", icon: "󰌶" },
                                            { id: "amoled", name: "AMOLED 0%", icon: "🖤" },
                                            { id: "blood", name: "Blood Red", icon: "🩸" },
                                            { id: "steel", name: "Steel", icon: "⚔️" }
                                        ]

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 32
                                            radius: 6
                                            readonly property bool isActive: settingsWindow.activeSurface === modelData.id
                                            color: isActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : (sMouse.containsMouse ? Theme.bg3 : Theme.bg2)
                                            border.color: isActive ? Theme.accent : (sMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Theme.bg3)
                                            border.width: isActive ? 1.5 : 1

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 4
                                                Text {
                                                    text: modelData.icon
                                                    font.family: "JetBrainsMono Nerd Font"
                                                    font.pixelSize: 10
                                                    color: parent.parent.isActive ? Theme.accent : Theme.fg1
                                                }
                                                Text {
                                                    text: modelData.name
                                                    font.family: "JetBrainsMono Nerd Font"
                                                    font.bold: true
                                                    font.pixelSize: 9
                                                    color: parent.parent.isActive ? Theme.accent : Theme.fg0
                                                }
                                            }

                                            MouseArea {
                                                id: sMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    settingsWindow.activeSurface = modelData.id
                                                    settingsWindow.runDetached(Quickshell.env("HOME") + "/.config/hypr/scripts/theme-switcher.sh --surface " + modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }

                                // Material Tint banner button
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 38
                                    radius: 6
                                    readonly property bool isActive: settingsWindow.activeSurface === "material"
                                    color: isActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : (matMouse.containsMouse ? Theme.bg3 : Theme.bg2)
                                    border.color: isActive ? Theme.accent : (matMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Theme.bg3)
                                    border.width: isActive ? 1.5 : 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            text: "󰏘"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 12
                                            color: Theme.accent
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text {
                                                text: "Material Tint (Dynamic Wallpaper Tone)"
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.bold: true
                                                font.pixelSize: 10
                                                color: parent.parent.parent.isActive ? Theme.accent : Theme.fg0
                                            }
                                        }

                                        Text {
                                            visible: parent.parent.isActive
                                            text: "󰄬 ACTIVE"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.bold: true
                                            font.pixelSize: 9
                                            color: Theme.accent
                                        }
                                    }

                                    MouseArea {
                                        id: matMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            settingsWindow.activeSurface = "material"
                                            settingsWindow.runDetached(Quickshell.env("HOME") + "/.config/hypr/scripts/theme-switcher.sh --surface material")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ================= TAB 1: PROCESSES & TASKS =================
            ScrollView {
                visible: settingsWindow.currentTab === 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                }

                ColumnLayout {
                    width: parent.width
                    spacing: 10

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
                                    Text { text: settingsWindow.hwRam + "%"; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 11; color: Theme.accent }
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
                                        color: Theme.accent
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
                                    Text { text: "󰋊 DISK"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Theme.silver }
                                    Item { Layout.fillWidth: true }
                                    Text { text: settingsWindow.hwDisk + "%"; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 11; color: Theme.accent }
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
                                        color: Theme.accent
                                    }
                                }
                            }
                        }
                    }

                    // Top Processes Header
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Active Resource Consumers"
                            font.family: "JetBrainsMono Nerd Font"
                            font.bold: true
                            font.pixelSize: 11
                            color: Theme.silver
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "RAM: " + settingsWindow.hwRamStr
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            color: Theme.gray
                        }
                    }

                    // Process Items
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: settingsWindow.topProcs

                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 6
                                color: Theme.bg1
                                border.color: Theme.bg2
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Text {
                                        text: "󰒋"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                        color: Theme.accent
                                    }

                                    Text {
                                        text: (modelData.name ?? "process")
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                        font.pixelSize: 10
                                        color: Theme.fg0
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: (modelData.cpu ?? "0") + "% CPU"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        color: Theme.silver
                                    }

                                    Text {
                                        text: (modelData.mem ?? "0") + "% RAM"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        color: Theme.silver
                                    }

                                    // Kill button
                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 4
                                        color: killMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.2) : Theme.bg2
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            color: killMouse.containsMouse ? Theme.red : Theme.silver
                                        }
                                        MouseArea {
                                            id: killMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.pid) {
                                                    settingsWindow.runDetached("kill -9 " + modelData.pid)
                                                    hwStatsProc.running = true
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

            // 3. Footer Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    height: 30
                    implicitWidth: leftActionRow.implicitWidth + 16
                    radius: 6
                    color: leftActionMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: leftActionMouse.containsMouse ? Theme.accent : Theme.bg3
                    border.width: 1

                    RowLayout {
                        id: leftActionRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: settingsWindow.currentTab === 0 ? "󰦛" : "󰑐"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: Theme.silver
                        }
                        Text {
                            text: settingsWindow.currentTab === 0 ? "Reset Defaults" : "Refresh Telemetry"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
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

                Text {
                    text: "ESC to close"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    color: Theme.silver
                }

                Rectangle {
                    height: 30
                    Layout.preferredWidth: 70
                    radius: 6
                    color: Theme.accent
                    Text {
                        anchors.centerIn: parent
                        text: "Done"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 10
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
