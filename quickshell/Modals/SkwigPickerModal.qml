import QtQuick
import qs.Common
import qs.Modals.Common
import qs.Modals.DankLauncherV2
import qs.Widgets

DankModal {
    id: root

    layerNamespace: "skwig:picker"
    modalWidth: Math.min(720, screenWidth - 100)
    modalHeight: Math.min(640, screenHeight - 100)
    showBackground: false
    backgroundColor: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)
    visible: false
    onBackgroundClicked: cancel()

    function openLinePicker(inputText: string, requestId: string, completionHandler): string {
        pickerController.searchQuery = "";
        pickerController.loadLinePicker(inputText, requestId, completionHandler);
        open();
        return "LINE_PICKER_OPEN_SUCCESS";
    }

    function openCliphistPicker(previewDir: string, cliphistCommand: string, requestId: string, completionHandler): string {
        pickerController.searchQuery = "";
        pickerController.loadCliphistPicker(previewDir, cliphistCommand, requestId, completionHandler);
        open();
        return "CLIPHIST_PICKER_OPEN_SUCCESS";
    }

    function cancel() {
        pickerController.cancel();
        close();
    }

    SkwigPickerController {
        id: pickerController
        onItemExecuted: root.close()
    }

    content: Component {
        FocusScope {
            id: contentRoot

            focus: true
            Component.onCompleted: Qt.callLater(() => searchField.forceActiveFocus())
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.cancel();
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_Up) {
                    pickerController.moveSelection(-1);
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_Down) {
                    pickerController.moveSelection(1);
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    pickerController.executeSelected();
                    event.accepted = true;
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                DankTextField {
                    id: searchField

                    width: parent.width
                    leftIconName: "search"
                    placeholderText: "Search"
                    text: pickerController.searchQuery
                    ignoreUpDownKeys: true
                    keyForwardTargets: [contentRoot]
                    onTextChanged: pickerController.setSearchQuery(text)
                    onAccepted: pickerController.executeSelected()
                }

                ResultsList {
                    width: parent.width
                    height: parent.height - y
                    controller: pickerController
                    transientSurfaceTracker: root.transientSurfaceTracker
                }
            }
        }
    }
}
