({
	doInit : function(component, event, helper) {
        var pageSize = component.get("v.cppageSize");
        helper.fetchFeaturedContents(component, pageSize);
    },
    
    viewMore : function(component, event, helper) {
    console.log('clicked');
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": "/news"
        });
        urlEvent.fire();
	},
}
)