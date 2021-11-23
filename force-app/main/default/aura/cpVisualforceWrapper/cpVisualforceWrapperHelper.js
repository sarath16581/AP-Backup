/**
 * Include the helper methods related to resize parent lightning components height based on the included visualforce page in the iframe
 * helper js could include any method related to communication between the VF page and the lightning componet as well as  to console.
 * 15th May 2018, Created by: Hasantha Liyanage
 **/

({
    init : function(component, event, helper) {
        var utility = component.find('utility');
        var loader = component.find('loader');
        
        //access the utility method to retrieve iframe VF url from custom setting Auspost setting 
        //custom setting object name and the list name
        utility.getCustomSettingListByName('AusPostSettings__c','VF_Iframe_Instance_URL', function(result) {
            component.set('v.baseUrl', result.URL__c);
        }, function(error) {}, loader);
        
        window.addEventListener("message", function(event) {
            if (event.origin !== component.get('v.baseUrl')) {
                // Not the expected origin: Reject the message!
                return;
            }
            
            // Handle the message
            if (event.data.name === "resize") {
                component.set("v.visualforcePageHeight", event.data.value);
                
            } else if (event.data.name === "opentab") {
                // if the mssage name is to open the tab, (make sure you are in a service console)
                var workspaceAPI = component.find('workspace');
                workspaceAPI.openTab({
                    recordId : event.data.id,
                    focus: true
                }).then(function(response) {
                    workspaceAPI.getTabInfo({
                        tabId: response
                    }).then(function(tabInfo) {
                        console.log('The url for this tab is: ' + tabInfo.url);
                    });
                })
                .catch(function(error) {
                    console.log(error);
                });
            } else if (event.data.name === "openvftab") {
                // if the mssage name is to open a visual force tab, (make sure you are in a service console)
                var workspaceAPI = component.find('workspace');
                workspaceAPI.openTab({
                    url  : event.data.url,
                    focus: true
                }).then(function(response) {
                    workspaceAPI.getFocusedTabInfo().then(function(response) {
                        var focusedTabId = response.tabId;
                        // setting the tab label
                        workspaceAPI.setTabLabel({
                            tabId: focusedTabId,
                            label: event.data.tabLabel
                        });
                        //setting the tab icon
                        workspaceAPI.setTabIcon({
                            tabId: focusedTabId,
                            icon: "action:approval",
                            iconAlt: "Approval"
                        });
                    }).then(function(tabInfo) {
                        console.log('The url for this tab is: ' + tabInfo.url);
                    });
                })
                .catch(function(error) {
                    console.log(error);
                });
            }
            
        }, true);
    }
})