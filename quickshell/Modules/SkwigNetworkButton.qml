import QtQuick
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    required property var networkPopout
    signal clicked(var button)

    width: 40
    radius: 4
    color: {
        if (networkPopout?.shouldBeVisible)
            return Qt.rgba(1, 1, 1, 0.16);

        if (mouseArea.containsMouse)
            return Qt.rgba(1, 1, 1, 0.10);

        return "transparent";
    }

    DankIcon {
        anchors.centerIn: parent
        name: {
            if (!NetworkService.networkAvailable || NetworkService.networkStatus === "disconnected")
                return "wifi_off";

            if (NetworkService.networkStatus === "ethernet")
                return "lan";

            return NetworkService.wifiSignalIcon || "wifi_off";
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
