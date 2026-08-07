pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string brightnessctlPath: Quickshell.env("SKWIG_BRIGHTNESSCTL") || ""
    readonly property string udevadmPath: Quickshell.env("SKWIG_UDEVADM") || ""
    readonly property string stdbufPath: Quickshell.env("SKWIG_STDBUF") || ""
    readonly property bool enabled: brightnessctlPath !== "" && udevadmPath !== "" && stdbufPath !== ""

    property string deviceName: ""
    readonly property string lastIpcDevice: deviceName === "" ? "" : "backlight:" + deviceName
    property bool brightnessAvailable: false
    property int brightnessLevel: 0

    property int _currentRaw: 0
    property int _maxRaw: 0
    property bool _brightnessReady: false
    property bool _maxReady: false
    property bool _initialized: false
    property bool _pendingShowOsd: false

    signal brightnessChanged(bool showOsd)

    function getCurrentDeviceInfo() {
        if (!brightnessAvailable || deviceName === "")
            return null;

        return {
            "id": lastIpcDevice,
            "name": deviceName,
            "class": "backlight",
            "current": _currentRaw,
            "percentage": brightnessLevel,
            "max": _maxRaw,
            "backend": "sysfs",
            "displayMax": 100
        };
    }

    function setBrightness(percentage, device, suppressOsd) {
        if (!enabled || deviceName === "")
            return;

        const value = Math.max(1, Math.min(100, Math.round(percentage)));
        Quickshell.execDetached([
            brightnessctlPath,
            "-q",
            "-d",
            deviceName,
            "set",
            value + "%"
        ]);
    }

    function handleUdevLine(line) {
        if (!line.includes(" change "))
            return;

        const match = line.match(/\/([^\/\s]+)\s+\(backlight\)\s*$/);
        if (!match)
            return;

        const newDevice = match[1];
        _pendingShowOsd = true;

        if (deviceName !== newDevice) {
            deviceName = newDevice;
            _brightnessReady = false;
            _maxReady = false;
            return;
        }

        _brightnessReady = false;
        brightnessFile.reload();
    }

    function publishIfReady() {
        if (!_brightnessReady || !_maxReady)
            return;

        const current = parseInt(brightnessFile.text().trim(), 10);
        const maxValue = parseInt(maxBrightnessFile.text().trim(), 10);
        if (isNaN(current) || isNaN(maxValue) || maxValue <= 0)
            return;

        const nextLevel = Math.max(0, Math.min(100, Math.round(current * 100 / maxValue)));
        const oldLevel = brightnessLevel;
        const firstUpdate = !_initialized;

        _currentRaw = current;
        _maxRaw = maxValue;
        brightnessLevel = nextLevel;
        brightnessAvailable = true;
        _initialized = true;

        if (_pendingShowOsd && (firstUpdate || oldLevel !== nextLevel))
            brightnessChanged(true);

        _pendingShowOsd = false;
    }

    FileView {
        id: brightnessFile
        path: root.deviceName === "" ? "" : "file:///sys/class/backlight/" + root.deviceName + "/brightness"
        printErrors: false

        onLoaded: {
            root._brightnessReady = true;
            root.publishIfReady();
        }
    }

    FileView {
        id: maxBrightnessFile
        path: root.deviceName === "" ? "" : "file:///sys/class/backlight/" + root.deviceName + "/max_brightness"
        printErrors: false

        onLoaded: {
            root._maxReady = true;
            root.publishIfReady();
        }
    }

    Process {
        id: udevMonitor
        command: [
            root.stdbufPath,
            "-oL",
            root.udevadmPath,
            "monitor",
            "--kernel",
            "--subsystem-match=backlight"
        ]

        stdout: SplitParser {
            onRead: line => root.handleUdevLine(line)
        }

        onExited: {
            if (root.enabled)
                monitorRestartTimer.restart();
        }
    }

    Timer {
        id: monitorRestartTimer
        interval: 1000
        repeat: false

        onTriggered: {
            if (root.enabled && !udevMonitor.running)
                udevMonitor.running = true;
        }
    }

    Component.onCompleted: {
        if (enabled)
            udevMonitor.running = true;
    }
}
