({
	doInit : function(component, event, helper) {
        var trendingDiscussionObject = component.get("v.TrendingDiscussion");
        component.set('v.discussion', {recordId: trendingDiscussionObject.feedElementId});
    },
    
	redirectToDetailPage : function(component, event, helper) {
        var trendingDiscussionObject = component.get("v.TrendingDiscussion");
        console.log('id: '+trendingDiscussionObject.feedElementId);
    	var navEvt = $A.get("e.force:navigateToSObject");
    	navEvt.setParams({
     	 "recordId": trendingDiscussionObject.feedElementId
    	});
    	navEvt.fire();
	},
})