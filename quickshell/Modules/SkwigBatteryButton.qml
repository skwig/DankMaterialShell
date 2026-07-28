import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    required property var batteryPopout

    signal clicked(var button)

    visible: BatteryService.batteryAvailable
    width: Math.max(40, content.implicitWidth + 16)
    radius: 4
    color: {
        if (batteryPopout?.shouldBeVisible)
            return Qt.rgba(1, 1, 1, 0.16);

        if (mouseArea.containsMouse)
            return Qt.rgba(1, 1, 1, 0.10);

        return "transparent";
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: 4

        DankIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: BatteryService.getBatteryIcon()
            size: 22
            color: BatteryService.isLowBattery && !BatteryService.isCharging ? Theme.error : "#ffffff"
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(BatteryService.batteryLevel) + "%"
            color: BatteryService.isLowBattery && !BatteryService.isCharging ? Theme.error : "#ffffff"
            font.pixelSize: 14
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked(root)
    }
}
