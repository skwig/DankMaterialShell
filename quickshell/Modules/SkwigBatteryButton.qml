import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    required property var batteryPopout

    signal clicked(var button)

    visible: BatteryService.batteryAvailable
    width: Math.max(Theme.barHeight - Theme.spacingS, content.implicitWidth + Theme.spacingL)
    radius: Theme.cornerRadius / 3
    color: {
        if (batteryPopout?.shouldBeVisible)
            return Theme.surfacePressed;

        if (mouseArea.containsMouse)
            return Theme.surfaceHover;

        return "transparent";
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: Theme.spacingXS

        DankIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: BatteryService.getBatteryIcon()
            size: Theme.iconSize - Theme.spacingXXS
            color: BatteryService.isLowBattery && !BatteryService.isCharging ? Theme.error : Theme.surfaceText
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(BatteryService.batteryLevel) + "%"
            color: BatteryService.isLowBattery && !BatteryService.isCharging ? Theme.error : Theme.surfaceText
            font.pixelSize: Theme.fontSizeMedium
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
