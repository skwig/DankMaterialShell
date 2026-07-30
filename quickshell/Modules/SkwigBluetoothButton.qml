import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    required property var bluetoothPopout
    signal clicked(var button)

    width: Theme.barHeight - Theme.spacingS
    radius: Theme.cornerRadius / 3
    color: {
        if (bluetoothPopout?.shouldBeVisible)
            return Theme.surfacePressed;

        if (mouseArea.containsMouse)
            return Theme.surfaceHover;

        return "transparent";
    }

    DankIcon {
        anchors.centerIn: parent
        name: {
            if (!BluetoothService.available || !BluetoothService.enabled)
                return "bluetooth_disabled";

            if (BluetoothService.connected)
                return "bluetooth_connected";

            return "bluetooth";
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
