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

    width: Theme.barHeight - Theme.spacingS
    radius: Theme.cornerRadius / 3
    color: {
        if (centerVisible)
            return Theme.surfacePressed;

        if (mouseArea.containsMouse)
            return Theme.surfaceHover;

        return "transparent";
    }

    Item {
        anchors.centerIn: parent
        width: Theme.iconSize
        height: Theme.iconSize

        DankIcon {
            id: notificationIcon

            anchors.centerIn: parent
            name: SessionData.doNotDisturb ? "notifications_off" : "notifications"
            size: Theme.iconSize - Theme.spacingXXS
            color: SessionData.doNotDisturb ? Theme.primary : Theme.surfaceText
        }

        Rectangle {
            width: Theme.spacingS - Theme.spacingXXS
            height: Theme.spacingS - Theme.spacingXXS
            radius: width / 2
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
