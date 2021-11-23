({
	doInit : function(component, event, helper) {
        var TopicObject = component.get("v.topic");
        component.set('v.routeInput', {recordId: TopicObject.Id});
    }
},
	redirectToDetailPage : function(component, event, helper) {
        
        console.log('in Related Topics redirectToDetailPage');
        var TopicObject = component.get("v.topic");
        console.log('id: '+TopicObject.Id);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": '/topic/' + TopicObject.Id
        });
        urlEvent.fire();
	},
})