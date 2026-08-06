pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property var item: null
    property bool requested: false
    property int sourceVersion: 0

    readonly property string cliphistId: String(item?.data?.cliphistId ?? "")
    readonly property string previewDir: String(item?.data?.previewDir ?? "")
    readonly property string cliphistCommand: String(item?.data?.cliphistCommand ?? "cliphist")
    readonly property string imageExt: String(item?.data?.imageExt ?? "")
    readonly property string previewPath: previewDir.length > 0 && cliphistId.length > 0 && imageExt.length > 0 ? previewDir + "/" + cliphistId + "." + imageExt : ""
    readonly property string previewSource: previewPath.length > 0 ? Paths.toFileUrl(previewPath) + "?v=" + sourceVersion : ""

    radius: Math.max(6, Theme.cornerRadius - 2)
    clip: true
    color: Theme.surfaceContainerHigh
    border.color: Theme.withAlpha(Theme.outline, 0.16)
    border.width: 1

    Component.onCompleted: decodePreview()
    onVisibleChanged: {
        if (visible)
            decodePreview();
    }
    onItemChanged: {
        requested = false;
        decodePreview();
    }

    function decodePreview() {
        if (requested || !visible || cliphistId.length === 0 || previewPath.length === 0)
            return;
        requested = true;
        decoder.command = ["/bin/sh", "-c", "printf '%s\\t\\n' \"$1\" | \"$2\" decode > \"$3\"", "_", cliphistId, cliphistCommand, previewPath];
        decoder.running = true;
    }

    Process {
        id: decoder

        running: false
        onExited: root.sourceVersion++
    }

    Image {
        id: previewImage

        anchors.fill: parent
        source: root.previewSource
        asynchronous: true
        cache: false
        smooth: true
        sourceSize.width: 128
        sourceSize.height: 128
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
    }

    DankIcon {
        anchors.centerIn: parent
        name: "image"
        size: Math.min(22, Math.max(16, root.height * 0.46))
        color: Theme.primary
        visible: previewImage.status !== Image.Ready
    }
}
