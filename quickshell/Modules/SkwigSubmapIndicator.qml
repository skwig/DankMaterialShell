import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string activeSubmap: ""

    function normalizeSubmap(value) {
        const submap = String(value ?? "").trim();

        if (submap === "" || submap === "reset" || submap === "default")
            return "";

        return submap;
    }

    visible: activeSubmap !== ""
    width: submapText.implicitWidth + Theme.spacingL + Theme.spacingXS
    height: Theme.iconSize + Theme.spacingXS
    radius: Theme.cornerRadius / 3
    color: Theme.surfacePressed

    Process {
        command: ["hyprctl", "submap"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.activeSubmap = root.normalizeSubmap(text);
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "submap" || event.name === "keybinds.submap")
                root.activeSubmap = root.normalizeSubmap(event.data);
        }
    }

    StyledText {
        id: submapText

        anchors.centerIn: parent
        text: root.activeSubmap
        color: Theme.primary
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
    }
}
