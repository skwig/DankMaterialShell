import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    required property var audioPopout
    signal clicked(var button)

    width: Theme.barHeight - Theme.spacingS
    radius: Theme.cornerRadius / 3
    color: {
        if (audioPopout?.shouldBeVisible)
            return Theme.surfacePressed;

        if (mouseArea.containsMouse)
            return Theme.surfaceHover;

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
        size: Theme.iconSize - Theme.spacingXXS
        color: Theme.surfaceText
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked(root)
    }
}
