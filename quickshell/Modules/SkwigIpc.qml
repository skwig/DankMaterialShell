import QtQuick
import Quickshell.Io

Item {
    id: root

    property var launcherModal: null
    property var pickerModal: null
    property var lockController: null
    property var powerMenuModal: null

    IpcHandler {
        id: ipc

        target: "skwig-dms"

        signal linePickerFinished(result: string)
        signal cliphistPickerFinished(result: string)
        signal appPickerFinished(result: string)

        function launcher(): string {
            if (!launcherModal)
                return "LAUNCHER_NOT_AVAILABLE";
            launcherModal.toggleWithMode("apps");
            return "LAUNCHER_OPEN_SUCCESS";
        }

        function lock(): string {
            if (!lockController)
                return "LOCK_NOT_AVAILABLE";
            lockController.lock();
            return "LOCK_SUCCESS";
        }

        function powerMenu(): string {
            if (!powerMenuModal)
                return "POWER_MENU_NOT_AVAILABLE";
            powerMenuModal.openCentered();
            return "POWER_MENU_OPEN_SUCCESS";
        }

        function appPicker(requestId: string): string {
            if (!launcherModal)
                return "APP_PICKER_NOT_AVAILABLE";
            launcherModal.pickApp(requestId, ipc);
            return "APP_PICKER_OPEN_SUCCESS";
        }

        function linePicker(inputText: string, requestId: string): string {
            if (!pickerModal)
                return "LINE_PICKER_NOT_AVAILABLE";
            return pickerModal.openLinePicker(inputText, requestId, ipc);
        }

        function cliphistPicker(previewDir: string, cliphistCommand: string, requestId: string): string {
            if (!pickerModal)
                return "CLIPHIST_PICKER_NOT_AVAILABLE";
            return pickerModal.openCliphistPicker(previewDir, cliphistCommand, requestId, ipc);
        }
    }
}
