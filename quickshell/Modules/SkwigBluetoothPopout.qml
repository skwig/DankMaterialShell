import QtQuick
import qs.Modals
import qs.Modules.ControlCenter.Details
import qs.Services
import qs.Widgets

DankPopoutStandalone {
    id: root

    layerNamespace: "skwig:bluetooth-poc"
    popupWidth: 520
    popupHeight: Math.min(620, Math.max(360, (screen?.height ?? 1080) - 96))
    positioning: ""
    fullHeightSurface: true

    onBackgroundClicked: close()

    Component.onDestruction: {
        if (PopoutService.controlCenterPopout === root)
            PopoutService.controlCenterPopout = null;
    }

    onShouldBeVisibleChanged: {
        if (!shouldBeVisible && BluetoothService.adapter?.discovering)
            BluetoothService.adapter.discovering = false;
    }

    content: Component {
        Item {
            BluetoothDetail {
                id: bluetoothDetail

                anchors.fill: parent
                bluetoothCodecModalRef: codecSelector

                onShowCodecSelector: device => {
                    codecSelector.show(device);
                }
            }

            BluetoothCodecSelector {
                id: codecSelector

                anchors.fill: parent
                z: 10000
                onCodecSelected: (deviceAddress, codecName) => {
                    bluetoothDetail.updateDeviceCodecDisplay(deviceAddress, codecName);
                }
            }
        }
    }
}
