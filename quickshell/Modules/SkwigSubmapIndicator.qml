import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string activeSubmap: ""

    visible: activeSubmap !== ""
    width: submapText.implicitWidth + 20
    height: 28
    radius: 4
    color: Qt.rgba(1, 1, 1, 0.14)

    StyledText {
        id: submapText

        anchors.centerIn: parent
        text: root.activeSubmap
        color: Theme.primary
        font.pixelSize: 14
        font.weight: Font.Medium
    }
}
