import QtQuick
import qs.Modules.Notifications.Center
import qs.Services

NotificationCenterPopout {
    id: root

    Component.onCompleted: {
        PopoutService.notificationCenterPopout = root;
    }

    Component.onDestruction: {
        if (PopoutService.notificationCenterPopout === root)
            PopoutService.notificationCenterPopout = null;
    }
}
