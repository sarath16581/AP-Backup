({
	doInit : function(component, event, helper) {
        var trendingTopicObject = component.get("v.TrendingTopic");
        component.set('v.routeInput', {recordId: trendingTopicObject.topicId});
},
	redirectToDetailPage : function(component, event, helper) {
        var trendingTopicObject = component.get("v.TrendingTopic");
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/topic/' + trendingTopicObject.topicId
        });
        urlEvent.fire();
        
	},
})