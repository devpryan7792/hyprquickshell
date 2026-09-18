pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root

    // Do Not Disturb state
    property bool dnd: false

    // Stored notifications for the Notification Center history
    // Each item: { id, appName, appIcon, summary, body, image, urgency, timeStr, timestamp, actions, rawNotif }
    property var historyList: []
    property int unreadCount: historyList.length

    // Active toast popups currently showing on screen
    property var popupList: []

    signal notificationAdded(var item)

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notif => {
            notif.tracked = true
            root.handleNotification(notif)
        }
    }

    function handleNotification(notif) {
        let actionList = []
        if (notif.actions) {
            for (let i = 0; i < notif.actions.length; i++) {
                actionList.push(notif.actions[i])
            }
        }

        let item = {
            id: notif.id,
            appName: notif.appName && notif.appName.length > 0 ? notif.appName : "System",
            appIcon: notif.appIcon ?? "",
            summary: notif.summary ?? "",
            body: notif.body ?? "",
            image: notif.image ?? "",
            urgency: notif.urgency, // 0: Low, 1: Normal, 2: Critical
            timeStr: Qt.formatTime(new Date(), "hh:mm AP"),
            timestamp: Date.now(),
            actions: actionList,
            rawNotif: notif
        }

        // Add to history (newest first)
        let hist = root.historyList.slice()
        // If an item with same ID exists, update it
        let existingIdx = hist.findIndex(h => h.id === item.id)
        if (existingIdx >= 0) {
            hist[existingIdx] = item
        } else {
            hist.unshift(item)
        }
        root.historyList = hist
        root.unreadCount = hist.length

        // Show toast popup if not in DND or if urgency is Critical (2)
        if (!root.dnd || item.urgency === 2) {
            let popups = root.popupList.slice()
            let pIdx = popups.findIndex(p => p.id === item.id)
            if (pIdx >= 0) {
                popups[pIdx] = item
            } else {
                popups.unshift(item)
            }
            root.popupList = popups
        }

        root.notificationAdded(item)
    }

    function dismissPopup(id) {
        let popups = root.popupList.slice()
        let idx = popups.findIndex(p => p.id === id)
        if (idx >= 0) {
            popups.splice(idx, 1)
            root.popupList = popups
        }
    }

    function removeNotification(id) {
        dismissPopup(id)
        let hist = root.historyList.slice()
        let idx = hist.findIndex(h => h.id === id)
        if (idx >= 0) {
            let item = hist[idx]
            if (item.rawNotif && typeof item.rawNotif.dismiss === "function") {
                try { item.rawNotif.dismiss() } catch(e) {}
            }
            hist.splice(idx, 1)
            root.historyList = hist
            root.unreadCount = hist.length
        }
    }

    function clearAll() {
        let popups = root.popupList.slice()
        for (let i = 0; i < popups.length; i++) {
            if (popups[i].rawNotif && typeof popups[i].rawNotif.dismiss === "function") {
                try { popups[i].rawNotif.dismiss() } catch(e) {}
            }
        }
        let hist = root.historyList.slice()
        for (let i = 0; i < hist.length; i++) {
            if (hist[i].rawNotif && typeof hist[i].rawNotif.dismiss === "function") {
                try { hist[i].rawNotif.dismiss() } catch(e) {}
            }
        }
        root.popupList = []
        root.historyList = []
        root.unreadCount = 0
    }

    function toggleDnd() {
        root.dnd = !root.dnd
    }
}
