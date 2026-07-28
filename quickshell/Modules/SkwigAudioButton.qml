import QtQuick
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    required property var audioPopout
    signal clicked(var button)

    width: 40
    radius: 4
    color: {
        if (audioPopout?.shouldBeVisible)
            return Qt.rgba(1, 1, 1, 0.16);

        if (mouseArea.containsMouse)
            return Qt.rgba(1, 1, 1, 0.10);

        return "transparent";
    }

    DankIcon {
        anchors.centerIn: parent
        name: {
            const audio = AudioService.sink?.audio;

            if (!audio || audio.muted || audio.volume <= 0)
                return "volume_off";

            if (audio.volume <= 0.33)
                return "volume_down";

            return "volume_up";
        }
        size: 22
        color: "#ffffff"
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked(root)
    }
}
