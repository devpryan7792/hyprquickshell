import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: wallpaperPickerWindow

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
        wallpaperPickerWindow.requestClose()
    }

    // Click outside backdrop to close
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)

        MouseArea {
            anchors.fill: parent
            onClicked: wallpaperPickerWindow.close()
        }
    }

    property var wallpapers: []
    property string searchQuery: ""
    property var filteredWallpapers: {
        let q = searchQuery.trim().toLowerCase()
        if (!q) return wallpapers
        return wallpapers.filter(p => p.toLowerCase().includes(q))
    }

    // Scanner process
    Process {
        id: wallScanner
        command: ["sh", "-c", "find $HOME/Pictures/wallpaper -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \\) | sort | python3 -c 'import sys, json; print(json.dumps([line.strip() for line in sys.stdin]))'"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    wallpaperPickerWindow.wallpapers = JSON.parse(data)
                } catch (e) {
                    console.warn("Failed to parse wallpaper json:", e)
                }
            }
        }
    }

    // Switcher process
    Process {
        id: wallSetter
        property var cmd: []
        command: cmd
        onExited: Theme.reload()
    }

    function selectWallpaper(path) {
        wallpaperPickerWindow.close()
        wallSetter.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/theme-switcher.sh", path]
        wallSetter.running = true
    }

    Timer {
        id: focusTimer
        interval: 10
        onTriggered: searchField.forceActiveFocus()
    }

    onVisibleChanged: {
        if (visible) {
            searchQuery = ""
            searchField.text = ""
            grid.currentIndex = 0
            focusTimer.restart()
            if (wallpapers.length === 0) {
                wallScanner.running = true
            }
        }
    }

    Component.onCompleted: {
        wallScanner.running = true
    }

    // Modal Box (Snappy 60ms)
    Rectangle {
        id: modalBox
        width: Math.min(940, parent.width - 40)
        height: Math.min(600, parent.height - 60)
        anchors.centerIn: parent
        radius: 8
        color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.96)
        border.color: Theme.accent
        border.width: 1
        clip: true

        opacity: wallpaperPickerWindow.visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 60 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "󰸉  Wallpaper & Dynamic Palette Engine"
                    font.family: "JetBrainsMono Nerd Font"
                    font.bold: true
                    font.pixelSize: 14
                    color: Theme.fg0
                }

                Item { Layout.fillWidth: true }

                // Search Box
                Rectangle {
                    width: 240
                    height: 34
                    radius: 6
                    color: Theme.bg1
                    border.color: searchField.activeFocus ? Theme.accent : Theme.bg3
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Text {
                            text: "󰍉"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            color: Theme.gray
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: Theme.fg0
                            clip: true
                            onTextChanged: {
                                wallpaperPickerWindow.searchQuery = text
                                grid.currentIndex = 0
                            }

                            Text {
                                text: "Filter wallpapers..."
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: Theme.gray
                                visible: !searchField.text && !searchField.activeFocus
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // 100% Keyboard navigation
                            Keys.onPressed: event => {
                                let cols = Math.floor(grid.width / grid.cellWidth) || 1
                                if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                                    if (grid.currentIndex < wallpaperPickerWindow.filteredWallpapers.length - 1) grid.currentIndex++
                                    grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                                    if (grid.currentIndex > 0) grid.currentIndex--
                                    grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Down) {
                                    if (grid.currentIndex + cols < wallpaperPickerWindow.filteredWallpapers.length) {
                                        grid.currentIndex += cols
                                        grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Up) {
                                    if (grid.currentIndex - cols >= 0) {
                                        grid.currentIndex -= cols
                                        grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (wallpaperPickerWindow.filteredWallpapers.length > 0 && grid.currentIndex >= 0 && grid.currentIndex < wallpaperPickerWindow.filteredWallpapers.length) {
                                        wallpaperPickerWindow.selectWallpaper(wallpaperPickerWindow.filteredWallpapers[grid.currentIndex])
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    wallpaperPickerWindow.close()
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }

                Text {
                    text: wallpaperPickerWindow.filteredWallpapers.length + " walls"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: Theme.gray
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 4
                    color: closeMouse.containsMouse ? Theme.bg3 : Theme.bg2
                    border.color: closeMouse.containsMouse ? Theme.accent : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: Theme.silver
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wallpaperPickerWindow.close()
                    }
                }
            }

            // Wallpaper Grid
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: 220
                cellHeight: 155
                model: wallpaperPickerWindow.filteredWallpapers

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    property bool isSelected: index === grid.currentIndex

                    width: 210
                    height: 145
                    radius: 6
                    color: Theme.bg1
                    border.color: isSelected ? Theme.accent : (cardMouse.containsMouse ? Theme.silver : Theme.bg2)
                    border.width: isSelected ? 2 : 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: "file://" + modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 420
                        sourceSize.height: 290
                    }

                    // Bottom info label overlay
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 24
                        color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.85)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.split("/").pop()
                            color: isSelected ? Theme.accent : Theme.fg1
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            font.bold: isSelected
                            elide: Text.ElideMiddle
                            width: parent.width - 12
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wallpaperPickerWindow.selectWallpaper(modelData)
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 4
                }
            }

            // Footer note
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "󰌌  Arrows/Tab to navigate • Enter to apply palette • Esc to close"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: Theme.gray
                }
                Item { Layout.fillWidth: true }
            }
        }
    }
}
