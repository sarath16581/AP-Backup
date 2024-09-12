/**
 * @description Aura wrapper to navigate to Opportunity Revenue 
 * This aura wrapper is required to be put in an url action as LWC is not addressable
 * @author Ken McGuire
 * @date 2024-02-06
 * @group Controller
 * @changelog
 * 2024-02-06- Ken McGuire - Created
 * 2024/07/31 - ken mcguire - refactored for revenue refresh function.
 */

({
    onPageReferenceChange : function(component, event, helper) {
        let myPageRef = component.get("v.pageReference");
        let id = myPageRef.state.c__oppId;
        component.set("v.recordId", id);

        // Assuming this action handles page reference change and also initializing
        var action = component.get("c.hasRefreshRevenuePermission");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.showButton", response.getReturnValue());
            } else {
                // Handle errors appropriately
                console.error('Error: ' + response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    
    handleRefreshRevenueClick: function(component, event, helper) {
		component.find('confirmRefreshModal').triggerModal();
	},
	
    handleModalEvent: function(component, event, helper) {
		var a = event.getSource();
		var componentSourceId = a.getLocalId();
		var eventType = event.getParam("type");

		if(componentSourceId == 'confirmRefreshModal' && eventType == 'OK') {
			helper.doRefreshRevenue(component, event, helper);
		}
	}
});