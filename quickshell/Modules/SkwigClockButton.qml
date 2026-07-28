import QtQuick
import qs.Widgets

Rectangle {
    id: root

    required property var calendarPopout
    property string clockText: "--:--"

    signal clicked(var button)

    width: Math.max(68, timeText.implicitWidth + 20)
    radius: 4
    color: {
        if (calendarPopout?.shouldBeVisible)
            return Qt.rgba(1, 1, 1, 0.16);

        if (mouseArea.containsMouse)
            return Qt.rgba(1, 1, 1, 0.10);

        return "transparent";
    }

    StyledText {
        id: timeText

        anchors.centerIn: parent
        text: root.clockText
        color: "#ffffff"
        font.pixelSize: 16
        font.weight: Font.Medium
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked(root)
    }
}
