import QtQuick
import qs.Modals
import qs.Modules.ControlCenter.Details
import qs.Services
import qs.Widgets

DankPopoutStandalone {
    id: root

    property real desiredContentHeight: 360

    layerNamespace: "skwig:battery-poc"
    popupWidth: 520
    popupHeight: Math.min(Math.max(320, desiredContentHeight), Math.max(320, (screen?.height ?? 1080) - 96))
    positioning: ""
    fullHeightSurface: true

    onBackgroundClicked: close()

    Component.onDestruction: {
        if (PopoutService.controlCenterPopout === root)
            PopoutService.controlCenterPopout = null;
    }

    content: Component {
        BatteryDetail {
            anchors.fill: parent

            Component.onCompleted: {
                root.desiredContentHeight = implicitHeight;
            }

            onImplicitHeightChanged: {
                root.desiredContentHeight = implicitHeight;
            }
        }
    }
}
