import QtQuick
import qs.Modals
import qs.Modules.ControlCenter.Details
import qs.Services
import qs.Widgets

DankPopoutStandalone {
    id: root

    layerNamespace: "skwig:audio-poc"
    popupWidth: 520
    popupHeight: Math.min(620, Math.max(360, (screen?.height ?? 1080) - 96))
    positioning: ""
    fullHeightSurface: true

    onBackgroundClicked: close()

    Component.onDestruction: {
        if (PopoutService.controlCenterPopout === root)
            PopoutService.controlCenterPopout = null;
    }

    content: Component {
        AudioOutputDetail {
            anchors.fill: parent
            hasVolumeSliderInCC: false
        }
    }
}
