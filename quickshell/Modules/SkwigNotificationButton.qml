import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    required property var notificationCenterPopout
    readonly property bool centerVisible: (notificationCenterPopout?.notificationHistoryVisible || notificationCenterPopout?.shouldBeVisible) ?? false
    readonly property bool hasNotifications: NotificationService.notifications.length > 0

    signal clicked(var button)

    width: 40
    radius: 4
    color: {
        if (centerVisible)
            return Qt.rgba(1, 1, 1, 0.16);

        if (mouseArea.containsMouse)
            return Qt.rgba(1, 1, 1, 0.10);

        return "transparent";
    }

    Item {
        anchors.centerIn: parent
        width: 24
        height: 24

        DankIcon {
            id: notificationIcon

            anchors.centerIn: parent
            name: SessionData.doNotDisturb ? "notifications_off" : "notifications"
            size: 22
            color: SessionData.doNotDisturb ? Theme.primary : "#ffffff"
        }

        Rectangle {
            width: 6
            height: 6
            radius: 3
            anchors {
                top: notificationIcon.top
                right: notificationIcon.right
            }
            color: Theme.error
            visible: root.hasNotifications
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
