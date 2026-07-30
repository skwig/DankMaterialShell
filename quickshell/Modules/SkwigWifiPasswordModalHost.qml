import QtQuick
import Quickshell
import qs.Modals
import qs.Services

LazyLoader {
    id: root

    active: false
    readonly property WifiPasswordModal loadedModal: item as WifiPasswordModal

    Component.onCompleted: {
        PopoutService.wifiPasswordModalLoader = root;
    }

    Component.onDestruction: {
        if (PopoutService.wifiPasswordModalLoader === root)
            PopoutService.wifiPasswordModalLoader = null;

        if (PopoutService.wifiPasswordModal === root.loadedModal)
            PopoutService.wifiPasswordModal = null;
    }

    WifiPasswordModal {
        id: wifiPasswordModal

        Component.onCompleted: {
            PopoutService.wifiPasswordModal = wifiPasswordModal;
        }
    }
}
