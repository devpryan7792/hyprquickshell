import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: overviewWindow

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
        overviewWindow.requestClose()
    }

    property var clientsList: []

    // Helper to map window class to Nerd Font icon
    function getAppGlyph(cls) {
        let c = (cls || "").toLowerCase()
        if (c.indexOf("ghostty") !== -1 || c.indexOf("kitty") !== -1 || c.indexOf("term") !== -1) return "󰞷"
        if (c.indexOf("firefox") !== -1) return "󰈹"
        if (c.indexOf("brave") !== -1 || c.indexOf("chrome") !== -1 || c.indexOf("browser") !== -1) return "󰊯"
        if (c.indexOf("code") !== -1 || c.indexOf("vsc") !== -1) return "󰨞"
        if (c.indexOf("antigravity") !== -1) return "󰚩"
        if (c.indexOf("thunar") !== -1 || c.indexOf("nautilus") !== -1 || c.indexOf("file") !== -1) return "󰉋"
        if (c.indexOf("discord") !== -1 || c.indexOf("vesktop") !== -1) return "󰙯"
        if (c.indexOf("spotify") !== -1 || c.indexOf("music") !== -1) return "󰓇"
        if (c.indexOf("steam") !== -1) return "󰓓"
        return "󰘔"
    }

    // Process to query active windows
    Process {
        id: clientsProc
        command: ["hyprctl", "-j", "clients"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    let raw = JSON.parse(data.trim())
                    let list = []
                    for (let i = 0; i < raw.length; i++) {
                        let c = raw[i]
                        // Only include real mapped client windows
                        if (c.mapped && c.workspace && c.workspace.id >= 0) {
                            list.push({
                                address: c.address,
                                title: (c.title && c.title.length > 0) ? c.title : (c.initialTitle || c.class),
                                appClass: (c.class && c.class.length > 0) ? c.class : "Application",
                                workspaceId: c.workspace.id,
                                workspaceName: c.workspace.name,
                                isFloating: c.floating,
                                pid: c.pid
                            })
                        }
                    }
                    overviewWindow.clientsList = list
                } catch (e) {
                    console.log("Overview parse error:", e)
                }
            }
        }
    }

    // Detached action dispatcher
    Process {
        id: dspProc
        property var cmd: []
        command: cmd
    }

    function runDetached(cmdStr) {
        dspProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/launch-app.sh", cmdStr]
        dspProc.running = true
    }

    function focusWindow(addr) {
        overviewWindow.close()
        runDetached("hyprctl dispatch 'hl.dsp.focus({ window = \"address:" + addr + "\" })'")
    }

    function closeTargetWindow(addr) {
        runDetached("hyprctl dispatch 'hl.dsp.window.close({ window = \"address:" + addr + "\" })'")
        refreshTimer.restart()
    }

    Timer {
        id: refreshTimer
        interval: 150
        repeat: false
        onTriggered: clientsProc.running = true
    }

    onVisibleChanged: {
        if (visible) {
            clientsProc.running = true
        }
    }

    // Esc key handler
    Item {
        anchors.fill: parent
        focus: overviewWindow.visible
        Keys.onEscapePressed: overviewWindow.close()
    }

    // Fullscreen backdrop with smooth blur and dimming
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.68)
        opacity: overviewWindow.visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: overviewWindow.close()
        }
    }

    // Exposé Canvas Container
    Item {
        anchors.fill: parent
        anchors.margins: 40

        ColumnLayout {
            anchors.fill: parent
            spacing: 24

            // Top Header Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 40
                    height: 40
                    radius: 10
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                    border.color: Theme.accent
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "󰕰"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: Theme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Native Window Overview & Exposé"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 18
                        color: Theme.fg0
                    }
                    Text {
                        text: overviewWindow.clientsList.length + " active windows • Click to switch & focus • Press Esc to dismiss"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Theme.silver
                    }
                }

                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: closeExposéMouse.containsMouse ? Theme.bg2 : Theme.bg1
                    border.color: Theme.bg3
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: closeExposéMouse.containsMouse ? Theme.red : Theme.silver
                    }
                    MouseArea {
                        id: closeExposéMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: overviewWindow.close()
                    }
                }
            }

            // Grid of Window Cards
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Flow {
                    id: cardsFlow
                    width: parent.width
                    spacing: 18

                    Repeater {
                        model: overviewWindow.clientsList

                        Rectangle {
                            width: Math.max(260, Math.min(340, (cardsFlow.width - (3 * 18)) / 4))
                            height: 150
                            radius: 14
                            color: cardMouse.containsMouse
                                   ? Qt.rgba(Theme.bg1.r, Theme.bg1.g, Theme.bg1.b, 0.95)
                                   : Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.9)
                            border.color: cardMouse.containsMouse ? Theme.accent : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                            border.width: cardMouse.containsMouse ? 1.5 : 1

                            scale: cardMouse.containsMouse ? 1.02 : 1.0
                            Behavior on scale {
                                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 140 }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                // Top row of card: Icon, Class, Workspace badge, Close btn
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: overviewWindow.getAppGlyph(modelData.appClass)
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 18
                                        color: Theme.accent
                                    }

                                    Text {
                                        text: modelData.appClass
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                        font.pixelSize: 12
                                        color: Theme.fg0
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    // Workspace Badge
                                    Rectangle {
                                        height: 20
                                        Layout.preferredWidth: wsText.implicitWidth + 12
                                        radius: 10
                                        color: Theme.bg2
                                        border.color: Theme.bg3
                                        border.width: 1
                                        Text {
                                            id: wsText
                                            anchors.centerIn: parent
                                            text: "WS " + modelData.workspaceName
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: Theme.silver
                                        }
                                    }

                                    // Close Window Button
                                    Rectangle {
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: closeWinMouse.containsMouse ? Theme.red : Theme.bg2
                                        Text {
                                            anchors.centerIn: parent
                                            text: "✕"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 10
                                            color: closeWinMouse.containsMouse ? Theme.bg0 : Theme.silver
                                        }
                                        MouseArea {
                                            id: closeWinMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: overviewWindow.closeTargetWindow(modelData.address)
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Theme.bg2
                                }

                                // Window Title preview
                                Text {
                                    text: modelData.title
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    color: Theme.fg1
                                    wrapMode: Text.Wrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }

                                // Card Footer: Floating tag & click hint
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: modelData.isFloating ? "󰉈 Floating" : "󰕰 Tiled"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        color: Theme.silver
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "Click to focus 󰁔"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 9
                                        color: cardMouse.containsMouse ? Theme.accent : Theme.silver
                                    }
                                }
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: overviewWindow.focusWindow(modelData.address)
                            }
                        }
                    }
                }
            }

            // Empty state placeholder
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: overviewWindow.clientsList.length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "󰕰"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 36
                        color: Theme.silver
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "No open windows on active workspaces"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 14
                        color: Theme.fg1
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
