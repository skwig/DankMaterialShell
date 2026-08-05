import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.Common

Scope {
    id: root

    property bool locked: false
    property bool authInProgress: false
    property string authMessage: ""
    property string pendingPassword: ""

    function lock() {
        if (locked)
            return;
        authMessage = "";
        pendingPassword = "";
        authInProgress = false;
        locked = true;
    }

    function unlock() {
        pam.abort();
        authInProgress = false;
        authMessage = "";
        pendingPassword = "";
        locked = false;
    }

    function authenticate(password: string) {
        if (!locked || authInProgress)
            return;
        pendingPassword = password;
        authMessage = "";
        authInProgress = true;
        if (!pam.start()) {
            authInProgress = false;
            pendingPassword = "";
            authMessage = "Authentication unavailable";
        }
    }

    PamContext {
        id: pam

        config: "login"
        configDirectory: "/etc/pam.d"

        onResponseRequiredChanged: {
            if (responseRequired)
                respond(root.pendingPassword);
        }

        onCompleted: result => {
            root.authInProgress = false;
            root.pendingPassword = "";
            if (result === PamResult.Success) {
                root.unlock();
            } else {
                root.authMessage = "Incorrect password";
            }
        }

        onError: {
            root.authInProgress = false;
            root.pendingPassword = "";
            root.authMessage = "Authentication error";
        }
    }

    WlSessionLock {
        id: sessionLock

        locked: root.locked

        SkwigLockSurface {
            authMessage: root.authMessage
            authInProgress: root.authInProgress
            onPasswordSubmitted: password => root.authenticate(password)
        }
    }
}
