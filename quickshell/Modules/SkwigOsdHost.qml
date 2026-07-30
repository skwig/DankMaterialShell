import QtQuick
import qs.Common
import qs.Services

Item {
    id: root

    property Component surfaces: null
    property bool surfacesLoaded: false
    property int pendingResumeReloads: 0

    function recreateSurfaces() {
        OSDManager.currentOSDsByScreen = ({});
        surfacesLoaded = false;
        surfaceReloadTimer.restart();
    }

    Component.onCompleted: {
        startupTimer.start();
    }

    Timer {
        id: startupTimer

        interval: 1000
        repeat: false

        onTriggered: {
            root.surfacesLoaded = true;
        }
    }

    Timer {
        id: surfaceReloadTimer

        interval: 120
        repeat: false

        onTriggered: {
            root.surfacesLoaded = true;
        }
    }

    Timer {
        id: resumeRecreateTimer

        interval: 400
        repeat: false

        onTriggered: {
            root.recreateSurfaces();
            root.pendingResumeReloads--;

            if (root.pendingResumeReloads <= 0) {
                root.pendingResumeReloads = 0;
                interval = 400;
                return;
            }

            interval = 1400;
            restart();
        }
    }

    Connections {
        target: SessionService

        function onSessionResumed() {
            root.pendingResumeReloads = 2;
            resumeRecreateTimer.interval = 400;
            resumeRecreateTimer.restart();
        }
    }

    Loader {
        active: root.surfacesLoaded && root.surfaces !== null
        asynchronous: false
        sourceComponent: root.surfaces
    }
}
