import QtQuick
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    required property var bluetoothPopout
    signal clicked(var button)

    width: 40
    radius: 4
    color: {
        if (bluetoothPopout?.shouldBeVisible)
            return Qt.rgba(1, 1, 1, 0.16);

        if (mouseArea.containsMouse)
            return Qt.rgba(1, 1, 1, 0.10);

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
