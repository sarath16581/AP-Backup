({
	fetchFeedElements : function(component) {
       
        var pageSize = component.get("v.cppageSize");
		var action = component.get("c.getFeedElements");
        action.setParams({"noOfRecordsToFetch" : pageSize});
        action.setCallback(this, function(response) {
            //console.log('chatter feed home page helper');
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.ChatterFeedWrapperElements", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
	},
})