({
    	doInit : function(component, event, helper) {
        var chatterFeedObject = component.get("v.ChatterFeedElmnt");
        component.set('v.ChatterLink', {recordId: chatterFeedObject.feedElementId});
},
	redirectToDetailPage : function(component, event, helper) {
        var chatterFeedObject = component.get("v.ChatterFeedElmnt");
    	var navEvt = $A.get("e.force:navigateToSObject");
    	navEvt.setParams({
     	 "recordId": chatterFeedObject.feedElementId
    	});
    	navEvt.fire();
	},
})