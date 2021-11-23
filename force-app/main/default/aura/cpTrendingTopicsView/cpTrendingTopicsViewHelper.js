({
	fetchTrendingTopics : function(component) {
        
        var pageSize = component.get("v.cppageSize");
		var action = component.get("c.getTrendingChatterTopics");
        action.setParams({"noOfRecordsToFetch" : pageSize});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.TrendingTopicsWrapperElements", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
	},
})