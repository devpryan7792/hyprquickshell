pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Reactive Material You Dynamic Colors
    property color bg0:       "#111318"
    property color bg1:       "#191c20"
    property color bg2:       "#1d2024"
    property color bg3:       "#282a2f"
    property color fg0:       "#e1e2e9"
    property color fg1:       "#e1e2e9"
    property color fg2:       "#c4c6d0"
    property color gray:      "#8d9199"
    property color silver:    "#43474e"
    property color accent:    "#a6c8ff"
    property color primary:   "#a6c8ff"
    property color secondary: "#bdc7dc"
    property color tertiary:  "#dbbde2"
    property color red:       "#ffb4ab"
    property color yellow:    "#e5c07b"
    property color teal:      "#4db6ac"
    property color purple:    "#c678dd"
    property color blue:      "#61afef"
    property color green:     "#98c379"
    property color orange:    "#d19a66"

    property string lastMtime: ""

    function applyColors(data) {
        if (!data) return
        if (data.bg0)       root.bg0 = data.bg0
        if (data.bg1)       root.bg1 = data.bg1
        if (data.bg2)       root.bg2 = data.bg2
        if (data.bg3)       root.bg3 = data.bg3
        if (data.fg0)       root.fg0 = data.fg0
        if (data.fg1)       root.fg1 = data.fg1
        if (data.fg2)       root.fg2 = data.fg2
        if (data.gray)      root.gray = data.gray
        if (data.silver)    root.silver = data.silver
        if (data.accent)    root.accent = data.accent
        if (data.primary)   root.primary = data.primary
        if (data.secondary) root.secondary = data.secondary
        if (data.tertiary)  root.tertiary = data.tertiary
        if (data.red)       root.red = data.red
        if (data.yellow)    root.yellow = data.yellow
        if (data.teal)      root.teal = data.teal
        if (data.purple)    root.purple = data.purple
        if (data.blue)      root.blue = data.blue
        if (data.green)     root.green = data.green
        if (data.orange)    root.orange = data.orange
    }

    Process {
        id: colorReader
        command: ["sh", "-c", "jq -c . \"$HOME/.config/quickshell/colors.json\" 2>/dev/null || cat \"$HOME/.config/quickshell/colors.json\" 2>/dev/null | tr -d '\\n'"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let d = JSON.parse(data.trim())
                    root.applyColors(d)
                } catch(e) {
                    console.warn("Theme JSON parse error:", e)
                }
            }
        }
    }

    function reload() {
        colorReader.running = true
    }

    // Monitor file modification time so external matugen / theme switches trigger instant live updates
    Process {
        id: mtimeChecker
        command: ["sh", "-c", "stat -c %Y \"$HOME/.config/quickshell/colors.json\" 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                let m = data.trim()
                if (m.length > 0 && m !== root.lastMtime) {
                    root.lastMtime = m
                    root.reload()
                }
            }
        }
    }

    Timer {
        id: watchTimer
        interval: 800
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: mtimeChecker.running = true
    }

    Component.onCompleted: {
        root.reload()
    }
}
