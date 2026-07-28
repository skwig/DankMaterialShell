import QtQuick
import qs.Widgets

Rectangle {
    id: root

    required property var currentScreen
    required property var trayMenuHost
    required property var systemTrayPopout

    signal clicked(var button)

    width: 40
    radius: 4
    color: {
        if (systemTrayPopout?.shouldBeVisible)
            return Qt.rgba(1, 1, 1, 0.16);

        if (mouseArea.containsMouse)
            return Qt.rgba(1, 1, 1, 0.10);

        return "transparent";
    }

    DankIcon {
        anchors.centerIn: parent
        name: "apps"
        size: 22
        color: "#ffffff"
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.systemTrayPopout.menuHost = root.trayMenuHost;
            root.systemTrayPopout.menuAnchorItem = root;
            root.systemTrayPopout.menuScreen = root.currentScreen;
            root.clicked(root);
        }
    }
}
