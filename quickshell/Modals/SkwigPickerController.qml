pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

Item {
    id: root

    property string searchQuery: ""
    property var sourceItems: []
    property var sections: []
    property var flatModel: []
    property int selectedFlatIndex: 0
    property bool keyboardNavigationActive: false
    property int viewModeVersion: 0
    property string requestId: ""
    property var completionHandler: null
    property string completionSignalName: "linePickerFinished"
    property var _cliphistLines: []
    property string _cliphistPreviewDir: ""
    property string _cliphistCommand: ""

    signal itemExecuted
    signal searchCompleted
    signal modeChanged(string mode, bool userInitiated)
    signal sectionExpanded(string sectionId)

    function loadLinePicker(inputText: string, newRequestId: string, newCompletionHandler) {
        requestId = newRequestId;
        completionHandler = newCompletionHandler;
        completionSignalName = "linePickerFinished";
        var lines = inputText.split(/\r?\n/).filter(line => line.length > 0);
        var items = [];
        for (var i = 0; i < lines.length; i++) {
            items.push({
                id: "picker_" + i,
                type: "app",
                name: lines[i],
                subtitle: "",
                icon: "list_alt",
                iconType: "material",
                section: "apps",
                data: {
                    value: lines[i]
                },
                source: "",
                actions: [],
                primaryAction: {
                    name: "Select",
                    icon: "check",
                    action: "select"
                }
            });
        }
        sourceItems = items;
        performSearch();
    }

    function loadCliphistPicker(previewDir: string, cliphistCommand: string, newRequestId: string, newCompletionHandler) {
        requestId = newRequestId;
        completionHandler = newCompletionHandler;
        completionSignalName = "cliphistPickerFinished";
        _cliphistPreviewDir = previewDir;
        _cliphistCommand = cliphistCommand;
        _cliphistLines = [];
        sourceItems = [];
        performSearch();
        cliphistListProcess.command = [cliphistCommand, "list"];
        cliphistListProcess.running = true;
    }

    function loadCliphistLines(lines, previewDir: string, cliphistCommand: string) {
        var items = [];
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            var tabIndex = line.indexOf("\t");
            var id = tabIndex >= 0 ? line.slice(0, tabIndex) : "";
            var label = tabIndex >= 0 ? line.slice(tabIndex + 1) : line;
            var lower = label.toLowerCase();
            var ext = "";
            var mime = "";
            if (lower.indexOf("[[ binary data ") >= 0) {
                if (lower.indexOf(" png ") >= 0) {
                    ext = "png";
                    mime = "image/png";
                } else if (lower.indexOf(" jpeg ") >= 0 || lower.indexOf(" jpg ") >= 0) {
                    ext = "jpg";
                    mime = "image/jpeg";
                } else if (lower.indexOf(" gif ") >= 0) {
                    ext = "gif";
                    mime = "image/gif";
                } else if (lower.indexOf(" webp ") >= 0) {
                    ext = "webp";
                    mime = "image/webp";
                } else if (lower.indexOf(" bmp ") >= 0) {
                    ext = "bmp";
                    mime = "image/bmp";
                }
            }
            items.push({
                id: "cliphist_" + (id.length > 0 ? id : i),
                type: "cliphist",
                name: label,
                subtitle: id.length > 0 ? "Clipboard #" + id : "Clipboard",
                icon: mime.length > 0 ? "image" : "content_paste",
                iconType: "material",
                section: "apps",
                data: {
                    value: line,
                    cliphistId: id,
                    previewDir: previewDir,
                    cliphistCommand: cliphistCommand,
                    imageExt: ext,
                    mimeType: mime
                },
                source: "",
                actions: [],
                primaryAction: {
                    name: "Select",
                    icon: "check",
                    action: "select"
                }
            });
        }
        sourceItems = items;
        performSearch();
    }

    Process {
        id: cliphistListProcess

        running: false
        stdout: SplitParser {
            onRead: line => {
                if (line.length > 0)
                    root._cliphistLines.push(line);
            }
        }
        onExited: root.loadCliphistLines(root._cliphistLines, root._cliphistPreviewDir, root._cliphistCommand)
    }

    function setSearchQuery(query: string) {
        searchQuery = query;
        performSearch();
    }

    function performSearch() {
        var query = searchQuery.toLowerCase().trim();
        var items = [];
        for (var i = 0; i < sourceItems.length; i++) {
            var item = sourceItems[i];
            if (!query || item.name.toLowerCase().includes(query))
                items.push(item);
        }

        sections = items.length > 0 ? [
            {
                id: "apps",
                title: "Options",
                icon: "list_alt",
                items: items,
                flatStartIndex: 0,
                collapsed: false
            }
        ] : [];
        flatModel = items.map(item => ({
                    item: item,
                    isHeader: false
                }));
        selectedFlatIndex = items.length > 0 ? 0 : -1;
        searchCompleted();
    }

    function moveSelection(delta: int) {
        if (flatModel.length === 0)
            return;
        selectedFlatIndex = Math.max(0, Math.min(flatModel.length - 1, selectedFlatIndex + delta));
        keyboardNavigationActive = true;
    }

    function executeSelected() {
        executeItem(flatModel[selectedFlatIndex]?.item ?? null);
    }

    function executeItem(item) {
        if (!item)
            return;
        if (completionHandler)
            completionHandler[completionSignalName](requestId + "\tselected\t" + (item.data?.value ?? item.name ?? ""));
        itemExecuted();
    }

    function cancel() {
        if (completionHandler)
            completionHandler[completionSignalName](requestId + "\tcancelled\t");
    }

    function getSectionViewMode(sectionId) {
        return "list";
    }

    function getGridColumns(sectionId) {
        return 1;
    }

    function canChangeSectionViewMode(sectionId) {
        return false;
    }

    function canCollapseSection(sectionId) {
        return false;
    }
}
