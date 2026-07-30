import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    required property var networkPopout
    signal clicked(var button)

    width: Theme.barHeight - Theme.spacingS
    radius: Theme.cornerRadius / 3
    color: {
        if (networkPopout?.shouldBeVisible)
            return Theme.surfacePressed;

        if (mouseArea.containsMouse)
            return Theme.surfaceHover;

        return "transparent";
    }

    DankIcon {
        anchors.centerIn: parent
        name: {
            if (!NetworkService.networkAvailable)
                return "wifi_off";

            if (NetworkService.ethernetConnected)
                return "lan";

            if (NetworkService.networkStatus === "disconnected")
                return "wifi_off";

            return NetworkService.wifiSignalIcon || "wifi_off";
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
