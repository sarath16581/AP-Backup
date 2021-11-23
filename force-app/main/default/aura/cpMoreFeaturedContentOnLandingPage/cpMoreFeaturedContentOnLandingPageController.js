({
	doInit : function(component, event, helper) {
        var pageSize = component.get("v.cppageSize");
		helper.fetchMoreFeaturedContents(component, pageSize);
	},
    
    redirectToDetailPage : function(component, event, helper) {
        var selectedItem = event.currentTarget; // Get the target object
        var index = selectedItem.dataset.record; // Get its value i.e. the index
        var selectedFeaturedContent = component.get("v.FeaturedContents")[index];
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/article/' + selectedFeaturedContent.KnowledgeArticleId
        });
        urlEvent.fire();
	},
    
    viewMore : function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": "/news"
        });
        urlEvent.fire();
	}
})