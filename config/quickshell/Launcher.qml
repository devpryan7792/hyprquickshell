import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io

PanelWindow {
    id: launcherWindow

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
        launcherWindow.requestClose()
    }

    property string currentMode: "apps" // "apps", "clip", "calc"

    function openApps() {
        currentMode = "apps"
        searchField.text = ""
        launcherWindow.search = ""
        itemsList.currentIndex = 0
        focusTimer.restart()
        if (allApps.length === 0) appScanner.running = true
    }

    function openClip() {
        currentMode = "clip"
        searchField.text = ""
        launcherWindow.search = ""
        itemsList.currentIndex = 0
        focusTimer.restart()
        clipScanner.running = true
    }

    // Click outside backdrop to close
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)

        MouseArea {
            anchors.fill: parent
            onClicked: launcherWindow.close()
        }
    }

    // Apps state
    property var allApps: []
    property string search: ""

    property var filteredApps: {
        let q = search.trim().toLowerCase()
        if (!q) return allApps

        let matches = []
        for (let i = 0; i < allApps.length; i++) {
            let app = allApps[i]
            let nameLower = app.name.toLowerCase()
            let score = 0
            if (nameLower === q) {
                score = 1000 + (app.score || 0)
            } else if (nameLower.startsWith(q)) {
                score = 500 + (app.score || 0)
            } else if (nameLower.includes(q)) {
                score = 200 + (app.score || 0)
            } else if (app.search && app.search.includes(q)) {
                score = 100 + (app.score || 0)
            }
            if (score > 0) {
                matches.push({ app: app, searchScore: score })
            }
        }
        matches.sort((a, b) => b.searchScore - a.searchScore)
        return matches.map(m => m.app)
    }

    // Clipboard state
    property var clipHistory: []
    property var filteredClips: {
        let q = search.trim().toLowerCase()
        if (!q) return clipHistory
        return clipHistory.filter(c => c.preview.toLowerCase().includes(q))
    }

    // Quick Math / Calculator evaluation
    property string calcResult: {
        let textTrim = search.trim()
        if (textTrim.startsWith("=")) {
            let expr = textTrim.substring(1).trim()
            if (!expr) return ""
            try {
                // Safe basic arithmetic eval
                if (!/^[0-9+\-*/()., %^e\s]+$/.test(expr)) return "Invalid expression"
                let sanitized = expr.replace(/\^/g, "**")
                let res = Function('"use strict"; return (' + sanitized + ')')()
                if (res !== undefined && !isNaN(res)) return String(res)
            } catch (e) {
                return ""
            }
        }
        return ""
    }

    // Process to scan desktop files
    Process {
        id: appScanner
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/get-apps.py"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    launcherWindow.allApps = JSON.parse(data)
                } catch (e) {
                    console.warn("Failed to parse apps json:", e)
                }
            }
        }
    }

    // Process to scan clipboard
    Process {
        id: clipScanner
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/get-clipboard.py"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    launcherWindow.clipHistory = JSON.parse(data)
                } catch (e) {
                    console.warn("Failed to parse clip json:", e)
                }
            }
        }
    }

    // Process to execute chosen app or paste clip
    Process {
        id: actionRunner
        property var cmd: []
        command: cmd
    }

    function launch(execCmd, appName) {
        launcherWindow.close()
        actionRunner.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/launch-app.sh", execCmd, appName ?? ""]
        actionRunner.running = true
    }

    function pasteClip(idVal) {
        launcherWindow.close()
        actionRunner.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/paste-clip.sh", String(idVal)]
        actionRunner.running = true
    }

    function copyCalcResult(val) {
        launcherWindow.close()
        actionRunner.command = ["wl-copy", val]
        actionRunner.running = true
    }

    Timer {
        id: focusTimer
        interval: 20
        onTriggered: searchField.forceActiveFocus()
    }

    onVisibleChanged: {
        if (visible) {
            searchField.text = ""
            launcherWindow.search = ""
            itemsList.currentIndex = 0
            focusTimer.restart()
            if (currentMode === "apps") {
                appScanner.running = true
            } else {
                clipScanner.running = true
            }
        }
    }

    Component.onCompleted: {
        appScanner.running = true
    }

    // Central Spotlight Window
    Rectangle {
        id: card
        width: 620
        height: 540
        anchors.centerIn: parent
        radius: 8
        color: Qt.rgba(Theme.bg0.r, Theme.bg0.g, Theme.bg0.b, 0.96)
        border.color: Theme.accent
        border.width: 1
        clip: true

        opacity: launcherWindow.visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 50 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Top Header: Mode Switcher Tabs
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Apps Tab
                Rectangle {
                    height: 30
                    implicitWidth: 96
                    radius: 5
                    color: launcherWindow.currentMode === "apps" ? Theme.accent : Theme.bg1
                    border.color: launcherWindow.currentMode === "apps" ? Theme.accent : Theme.bg3
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰀻"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: launcherWindow.currentMode === "apps" ? Theme.bg0 : Theme.fg1
                        }
                        Text {
                            text: "Apps"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                            color: launcherWindow.currentMode === "apps" ? Theme.bg0 : Theme.fg1
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: launcherWindow.openApps()
                    }
                }

                // Clipboard Tab
                Rectangle {
                    height: 30
                    implicitWidth: 120
                    radius: 5
                    color: launcherWindow.currentMode === "clip" ? Theme.accent : Theme.bg1
                    border.color: launcherWindow.currentMode === "clip" ? Theme.accent : Theme.bg3
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰅍"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: launcherWindow.currentMode === "clip" ? Theme.bg0 : Theme.fg1
                        }
                        Text {
                            text: "Clipboard"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                            color: launcherWindow.currentMode === "clip" ? Theme.bg0 : Theme.fg1
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: launcherWindow.openClip()
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: launcherWindow.currentMode === "apps"
                          ? (launcherWindow.filteredApps.length + " apps available")
                          : (launcherWindow.filteredClips.length + " clips saved")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: Theme.gray
                }
            }

            // Search Header Box
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 6
                color: Theme.bg1
                border.color: searchField.activeFocus ? Theme.accent : Theme.bg3
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: launcherWindow.currentMode === "apps" ? "󰍉" : "󰅍"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: searchField.activeFocus ? Theme.accent : Theme.gray
                    }

                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        color: Theme.fg0
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        selectByMouse: true
                        clip: true

                        Text {
                            text: launcherWindow.currentMode === "apps"
                                  ? "Search apps, generic, '=math', '>cmd', ';' for clip..."
                                  : "Search copied text snippet..."
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: Theme.gray
                            visible: !searchField.text && !searchField.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        onTextChanged: {
                            let t = text
                            if (launcherWindow.currentMode === "apps" && t.startsWith(";")) {
                                launcherWindow.openClip()
                                text = t.substring(1)
                                return
                            }
                            launcherWindow.search = text
                            itemsList.currentIndex = 0
                        }

                        // 100% keyboard-driven navigation
                        Keys.onPressed: event => {
                            let count = (launcherWindow.currentMode === "apps")
                                        ? launcherWindow.filteredApps.length
                                        : launcherWindow.filteredClips.length

                            if (event.key === Qt.Key_Down || (event.modifiers & Qt.ControlModifier && (event.key === Qt.Key_N || event.key === Qt.Key_J))) {
                                if (itemsList.currentIndex < count - 1) {
                                    itemsList.currentIndex++
                                    itemsList.positionViewAtIndex(itemsList.currentIndex, ListView.Contain)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up || (event.modifiers & Qt.ControlModifier && (event.key === Qt.Key_P || event.key === Qt.Key_K))) {
                                if (itemsList.currentIndex > 0) {
                                    itemsList.currentIndex--
                                    itemsList.positionViewAtIndex(itemsList.currentIndex, ListView.Contain)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Tab) {
                                if (searchField.text.length === 0) {
                                    if (launcherWindow.currentMode === "apps") launcherWindow.openClip()
                                    else launcherWindow.openApps()
                                } else {
                                    if (itemsList.currentIndex < count - 1) itemsList.currentIndex++
                                    else itemsList.currentIndex = 0
                                    itemsList.positionViewAtIndex(itemsList.currentIndex, ListView.Contain)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Backtab) {
                                if (itemsList.currentIndex > 0) itemsList.currentIndex--
                                else itemsList.currentIndex = count - 1
                                itemsList.positionViewAtIndex(itemsList.currentIndex, ListView.Contain)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                let t = searchField.text.trim()
                                // Quick calculator enter
                                if (launcherWindow.calcResult !== "") {
                                    launcherWindow.copyCalcResult(launcherWindow.calcResult)
                                    event.accepted = true
                                    return
                                }
                                // Quick terminal execution enter (> cmd)
                                if (t.startsWith(">")) {
                                    let cmd = t.substring(1).trim()
                                    if (cmd.length > 0) {
                                        launcherWindow.launch("ghostty -e " + cmd, cmd)
                                    }
                                    event.accepted = true
                                    return
                                }

                                if (launcherWindow.currentMode === "apps") {
                                    if (launcherWindow.filteredApps.length > 0 && itemsList.currentIndex >= 0 && itemsList.currentIndex < launcherWindow.filteredApps.length) {
                                        let item = launcherWindow.filteredApps[itemsList.currentIndex]
                                        launcherWindow.launch(item.exec, item.name)
                                    }
                                } else {
                                    if (launcherWindow.filteredClips.length > 0 && itemsList.currentIndex >= 0 && itemsList.currentIndex < launcherWindow.filteredClips.length) {
                                        launcherWindow.pasteClip(launcherWindow.filteredClips[itemsList.currentIndex].id)
                                    }
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                launcherWindow.close()
                                event.accepted = true
                            }
                        }
                    }

                    // Clear search button
                    Rectangle {
                        visible: searchField.text.length > 0
                        width: 20
                        height: 20
                        radius: 10
                        color: Theme.bg2
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: Theme.silver
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchField.text = ""
                                searchField.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            // Quick Math / Calc preview banner if active
            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: 6
                visible: launcherWindow.calcResult !== ""
                color: Theme.bg2
                border.color: Theme.accent
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Text {
                        text: "󰪚"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: Theme.accent
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "= " + launcherWindow.calcResult
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.fg0
                        }
                        Text {
                            text: "Press Enter to copy result to clipboard"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: Theme.silver
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: launcherWindow.copyCalcResult(launcherWindow.calcResult)
                }
            }

            // Results List
            ListView {
                id: itemsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: launcherWindow.currentMode === "apps" ? launcherWindow.filteredApps : launcherWindow.filteredClips

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    property bool isSelected: index === itemsList.currentIndex

                    width: itemsList.width
                    height: launcherWindow.currentMode === "apps" ? 50 : 44
                    radius: 6
                    color: isSelected ? Theme.bg2 : (itemMouse.containsMouse ? Qt.rgba(Theme.bg1.r, Theme.bg1.g, Theme.bg1.b, 0.45) : "transparent")
                    border.color: isSelected ? Theme.accent : "transparent"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Icon Container: High-res App Image or Letter Badge Fallback
                        Item {
                            visible: launcherWindow.currentMode === "apps"
                            width: 30
                            height: 30
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                id: appImg
                                anchors.fill: parent
                                source: (modelData.iconPath && modelData.iconPath.length > 0) ? ("file://" + modelData.iconPath) : ""
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                                visible: status === Image.Ready
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 5
                                color: isSelected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : Theme.bg1
                                border.color: isSelected ? Theme.accent : Theme.bg3
                                border.width: 1
                                visible: !appImg.visible

                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.name && modelData.name.length > 0) ? modelData.name.charAt(0).toUpperCase() : "󰀻"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: isSelected ? Theme.accent : Theme.fg1
                                }
                            }
                        }

                        // Clipboard Item Icon
                        Text {
                            visible: launcherWindow.currentMode === "clip"
                            text: "󰅍"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            color: isSelected ? Theme.accent : Theme.silver
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Text Details
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter

                            RowLayout {
                                spacing: 8
                                Text {
                                    text: launcherWindow.currentMode === "apps" ? modelData.name : modelData.preview
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    font.bold: isSelected
                                    color: isSelected ? Theme.fg0 : Theme.fg1
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // Frecency Star for top-used apps
                                Text {
                                    visible: launcherWindow.currentMode === "apps" && modelData.score > 0
                                    text: "★"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    color: Theme.accent
                                }
                            }

                            Text {
                                text: launcherWindow.currentMode === "apps" ? (modelData.subtitle ?? modelData.exec) : ("Clip #" + modelData.id)
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: isSelected ? Theme.silver : Theme.gray
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Selection Return Hint
                        Rectangle {
                            visible: isSelected
                            width: 22
                            height: 22
                            radius: 4
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                            border.color: Theme.accent
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "↵"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.accent
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (launcherWindow.currentMode === "apps") {
                                launcherWindow.launch(modelData.exec, modelData.name)
                            } else {
                                launcherWindow.pasteClip(modelData.id)
                            }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 4
                }
            }

            // Footer hint
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: launcherWindow.currentMode === "apps"
                          ? "󰌌  ↑↓/Tab nav • ↵ launch • =math • >cmd • ; clip • Esc exit"
                          : "󰌌  ↑↓/Tab nav • ↵ copy → Ctrl+V or middle-click • Esc exit"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: Theme.gray
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: launcherWindow.currentMode === "apps" ? "Frecency & Prefix scoring" : "Cliphist persistent history"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: Theme.silver
                }
            }
        }
    }
}
