({
	fetchChatterGroups : function(component, pageSize, groupVisibility) {
		var action = component.get("c.getCommunityGroups");
        var fetchConversationPageParam = component.get("c.getConversationSettings");
        action.setParams({"noOfRecordsToFetch" : pageSize,
                          "groupVisibility" : groupVisibility});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.cpChatterGroups", response.getReturnValue());
            }
            
            if(response.getReturnValue() == null){
                var cmpTarget = component.find('ChatterGroupsHeader');
        		$A.util.addClass(cmpTarget, 'slds-hide');
            }
        });
        
        fetchConversationPageParam.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.cpConversationPageId", response.getReturnValue());
            }
        });
        
        $A.enqueueAction(action);
        $A.enqueueAction(fetchConversationPageParam);
	},
})