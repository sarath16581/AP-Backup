({
	fetchTrendingDiscussions : function(component) {
        
        var pageSize = component.get("v.cppageSize");
        var sortingparam = component.get("v.cpSortingParam");
		var action = component.get("c.getTrendingDiscussions");
        action.setParams({"noOfRecordsToFetch" : pageSize,
                          "sortingParameter" : sortingparam
                         });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.TrendingDiscussionsWrapperElements", response.getReturnValue());
            }
            if(response.getReturnValue() == null){
                var cmpTarget = component.find('TrendingDiscussionHeader');
        		$A.util.addClass(cmpTarget, 'slds-hide');
            }
            
        });
        $A.enqueueAction(action);
        
	},
})