({
	doInit : function(component, event, helper) {
        
		helper.fetchTrendingTopics(component);
	},
    
    viewMore : function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": "/questions"
        });
        urlEvent.fire();
	},
    
})