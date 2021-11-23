({   
    onTabFocused: function(cmp, event, helper) {
        let workspace = cmp.find("workspace");
        let focusedTabId = event.getParam('currentTabId');
        workspace.getAllTabInfo().then(function (tabsInfo) {
            console.log(JSON.stringify(tabsInfo));
            //filter Lead tabs
            let focusedTab = tabsInfo.filter ((tab) =>{
                return tab.focused && tab.recordId != null && tab.recordId.startsWith('00Q') && tab.tabId == focusedTabId;
            });
            if (focusedTab.length > 0) {
                helper.openUtility(cmp);
            }
            else{
                helper.minimizeUtility(cmp);
            }
        });
    }
})