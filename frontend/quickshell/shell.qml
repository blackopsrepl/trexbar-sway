import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property string configPath: Quickshell.env("TREXBAR_SWAY_CONFIG") || ((Quickshell.env("HOME") || "") + "/.config/trexbar-sway/config.json")
    property string stateDir: Quickshell.env("TREXBAR_SWAY_STATE_DIR") || ((Quickshell.env("HOME") || "") + "/.local/state/trexbar-sway")
    property string trexbarBin: Quickshell.env("TREXBAR_SWAY_BIN") || "trexbar-sway"
    property string snapshotPath: stateDir + "/snapshot.json"
    property string uiPath: stateDir + "/ui.json"
    property string eventPath: stateDir + "/state-event.json"
    property string textFont: "Fira Code"
    property string iconFont: "Symbols Nerd Font Mono"
    property var viewData: snapshotAdapter.view && snapshotAdapter.view.summary ? snapshotAdapter.view : ({ summary: {}, sessions: [], agents: [], errors: [], headlineSession: null })
    property var summary: viewData.summary || ({})
    property var sessions: viewData.sessions || []
    property var agents: viewData.agents || []
    property var errors: viewData.errors || []
    property var headlineSession: viewData.headlineSession || null

    function runTrexbar(args) {
        if (actionRunner.running) {
            actionRunner.signal(9)
            actionRunner.running = false
        }

        actionRunner.command = [root.trexbarBin].concat(args).concat(["--config", root.configPath])
        actionRunner.running = true
    }

    function closeModal() {
        root.runTrexbar(["ui", "close"])
    }

    function statusColor(level) {
        if (level === "critical" || level === "error") {
            return "#E06C75"
        }
        if (level === "warning") {
            return "#F2C572"
        }
        if (level === "stale" || level === "loading") {
            return "#6A6E95"
        }
        return "#82FB9C"
    }

    function sessionStatusColor(session) {
        return root.statusColor(session && session.health ? session.health.level : "unknown")
    }

    function gitText(session) {
        if (!session || !session.git || !session.git.isRepo) {
            return "no git"
        }

        var parts = [session.git.badge || session.git.branch || "git"]
        if ((session.git.dirtyCount || 0) > 0) {
            parts.push("dirty " + session.git.dirtyCount)
        }
        if ((session.git.ahead || 0) > 0) {
            parts.push("ahead " + session.git.ahead)
        }
        if ((session.git.behind || 0) > 0) {
            parts.push("behind " + session.git.behind)
        }
        return parts.join("  ")
    }

    function sessionMeta(session) {
        if (!session) {
            return ""
        }

        return (session.activityLevel || "unknown") + "  " +
            (session.activityAgo || "unknown") + "  " +
            "CPU " + Math.round(session.stats ? (session.stats.cpuPercent || 0) : 0) + "%  " +
            "RAM " + (session.stats ? (session.stats.memMb || 0) : 0) + " MB"
    }

    Process {
        id: actionRunner
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length) {
                    console.log(text.trim())
                }
            }
        }
    }

    FileView {
        id: snapshotFile
        path: root.snapshotPath
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: snapshotAdapter
            property int snapshotVersion: 0
            property string generatedAt: ""
            property string status: "loading"
            property var summary: ({})
            property var sessions: []
            property var agents: []
            property var errors: []
            property var view: ({})
        }
    }

    FileView {
        id: uiFile
        path: root.uiPath
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: uiAdapter
            property bool open: false
            property string requestedAt: ""
        }
    }

    FileView {
        id: eventFile
        path: root.eventPath
        watchChanges: true
        onFileChanged: root.reloadState()
    }

    function reloadState() {
        snapshotFile.reload()
        uiFile.reload()
        eventFile.reload()
    }

    Component.onCompleted: root.reloadState()

    component MetricTile: Rectangle {
        property string label: ""
        property string value: ""
        property color accent: "#82FB9C"

        Layout.fillWidth: true
        Layout.preferredHeight: 74
        color: "#10131F"
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.5)
        border.width: 1
        radius: 6

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: label
                color: "#6A6E95"
                font.family: root.textFont
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: value
                color: accent
                font.family: root.textFont
                font.pixelSize: 24
                font.bold: true
                elide: Text.ElideRight
            }
        }
    }

    component IconButton: Rectangle {
        signal clicked()
        property string icon: ""
        property string label: ""
        property color accent: "#82FB9C"

        Layout.preferredWidth: 112
        Layout.preferredHeight: 38
        color: buttonArea.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.14) : "#151927"
        border.color: buttonArea.containsMouse ? accent : "#2E344A"
        border.width: 1
        radius: 6

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: icon
                color: accent
                font.family: root.iconFont
                font.pixelSize: 15
            }

            Text {
                text: label
                color: "#DDF7FF"
                font.family: root.textFont
                font.pixelSize: 12
            }
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    PanelWindow {
        id: modal
        visible: uiAdapter.open
        screen: Quickshell.screens.length ? Quickshell.screens[0] : null
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        focusable: true

        Shortcut {
            sequence: "Esc"
            context: Qt.WindowShortcut
            onActivated: root.closeModal()
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.02, 0.025, 0.045, 0.72)

            MouseArea {
                anchors.fill: parent
                onClicked: root.closeModal()
            }

            Rectangle {
                id: card
                width: Math.min(980, Math.max(620, parent.width - 96))
                height: parent.height - 96
                anchors.centerIn: parent
                color: "#0B0C16"
                border.color: "#82FB9C"
                border.width: 1
                radius: 8

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 7
                    color: "transparent"
                    border.color: "#26304A"
                    border.width: 1
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            color: "#111827"
                            border.color: "#82FB9C"
                            border.width: 1
                            radius: 8

                            Text {
                                anchors.centerIn: parent
                                text: "TRX"
                                color: "#82FB9C"
                                font.family: root.textFont
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                Layout.fillWidth: true
                                text: "trexbar"
                                color: "#DDF7FF"
                                font.family: root.textFont
                                font.pixelSize: 26
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (headlineSession ? (headlineSession.name + "  " + root.sessionMeta(headlineSession)) : "tmux session overview") +
                                    "  " + (snapshotAdapter.generatedAt || "waiting for data")
                                color: "#9CF7C2"
                                font.family: root.textFont
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 118
                            Layout.preferredHeight: 34
                            color: Qt.rgba(root.statusColor(snapshotAdapter.status).r, root.statusColor(snapshotAdapter.status).g, root.statusColor(snapshotAdapter.status).b, 0.13)
                            border.color: root.statusColor(snapshotAdapter.status)
                            border.width: 1
                            radius: 17

                            Text {
                                anchors.centerIn: parent
                                text: snapshotAdapter.status || "loading"
                                color: root.statusColor(snapshotAdapter.status)
                                font.family: root.textFont
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        IconButton {
                            icon: ""
                            label: "Refresh"
                            onClicked: root.runTrexbar(["refresh"])
                        }

                        IconButton {
                            icon: ""
                            label: "Close"
                            accent: "#85E1FB"
                            onClicked: root.closeModal()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        MetricTile {
                            label: "sessions"
                            value: summary.sessionCount || 0
                        }

                        MetricTile {
                            label: "attached"
                            value: summary.attachedCount || 0
                            accent: "#85E1FB"
                        }

                        MetricTile {
                            label: "agents"
                            value: summary.agentCount || 0
                            accent: "#F2C572"
                        }

                        MetricTile {
                            label: "dirty repos"
                            value: summary.dirtyRepoCount || 0
                            accent: (summary.dirtyRepoCount || 0) > 0 ? "#E5C07B" : "#82FB9C"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 240
                        color: "#0F1320"
                        border.color: "#242B40"
                        border.width: 1
                        radius: 8

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "sessions"
                                    color: "#DDF7FF"
                                    font.family: root.textFont
                                    font.pixelSize: 14
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: (summary.activeCount || 0) + " active  " +
                                        (summary.idleCount || 0) + " idle  " +
                                        (summary.dormantCount || 0) + " dormant"
                                    color: "#6A6E95"
                                    font.family: root.textFont
                                    font.pixelSize: 11
                                }
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                model: root.sessions
                                clip: true
                                spacing: 8

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 72
                                    color: modelData.attached ? "#13221C" : (index % 2 === 0 ? "#151927" : "#10131F")
                                    border.color: modelData.attached ? "#82FB9C" : "#252B3F"
                                    border.width: 1
                                    radius: 7

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 10

                                        Rectangle {
                                            Layout.preferredWidth: 10
                                            Layout.fillHeight: true
                                            color: root.sessionStatusColor(modelData)
                                            radius: 5
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 5

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.name || "unnamed"
                                                    color: "#DDF7FF"
                                                    font.family: root.textFont
                                                    font.pixelSize: 15
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    text: modelData.attached ? "attached" : "detached"
                                                    color: modelData.attached ? "#82FB9C" : "#6A6E95"
                                                    font.family: root.textFont
                                                    font.pixelSize: 11
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: root.gitText(modelData)
                                                color: "#85E1FB"
                                                font.family: root.textFont
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: root.sessionMeta(modelData)
                                                color: "#9CF7C2"
                                                font.family: root.textFont
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Text {
                                            Layout.preferredWidth: 66
                                            text: modelData.health ? (modelData.health.score || 0) : "-"
                                            color: root.sessionStatusColor(modelData)
                                            font.family: root.textFont
                                            font.pixelSize: 24
                                            font.bold: true
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        visible: root.agents.length > 0 || root.errors.length > 0
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            Layout.fillWidth: true
                            visible: root.agents.length > 0
                            text: "agents  " + root.agents.map(function(agent) {
                                return agent.processName + " / " + agent.projectName
                            }).join("    ")
                            color: "#F2C572"
                            font.family: root.textFont
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: root.errors.length > 0
                            text: "errors  " + root.errors.map(function(error) {
                                return error.message
                            }).join("    ")
                            color: "#E06C75"
                            font.family: root.textFont
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
