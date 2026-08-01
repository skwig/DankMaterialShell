import QtQuick
import Quickshell.Io

Item {
    id: root

    property var launcherModal: null
    property var pickerModal: null

    IpcHandler {
        id: ipc

        target: "skwig-dms"

        signal pickerFinished(result: string)
        signal appPickerFinished(result: string)

        function launcher(): string {
            if (!launcherModal)
                return "LAUNCHER_NOT_AVAILABLE";
            launcherModal.toggleWithMode("apps");
            return "LAUNCHER_OPEN_SUCCESS";
        }

        function appPicker(requestId: string): string {
            if (!launcherModal)
                return "APP_PICKER_NOT_AVAILABLE";
            launcherModal.pickApp(requestId, ipc);
            return "APP_PICKER_OPEN_SUCCESS";
        }

        function picker(inputText: string, requestId: string): string {
            if (!pickerModal)
                return "PICKER_NOT_AVAILABLE";
            return pickerModal.openPicker(inputText, requestId, ipc);
        }
    }
}
