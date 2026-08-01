pragma ComponentBehavior: Bound

import QtQuick

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

    signal itemExecuted
    signal searchCompleted
    signal modeChanged(string mode, bool userInitiated)
    signal sectionExpanded(string sectionId)

    function load(inputText: string, newRequestId: string, newCompletionHandler) {
        requestId = newRequestId;
        completionHandler = newCompletionHandler;
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
            completionHandler.pickerFinished(requestId + "\tselected\t" + (item.data?.value ?? item.name ?? ""));
        itemExecuted();
    }

    function cancel() {
        if (completionHandler)
            completionHandler.pickerFinished(requestId + "\tcancelled\t");
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
