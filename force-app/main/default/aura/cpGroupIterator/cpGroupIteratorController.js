({
    doInit : function(component, event, helper) {
        var ChatterGroupObject = component.get("v.ChatterGroup");
        component.set('v.GroupLink', {recordId: ChatterGroupObject.groupId});
    },
	redirectToDetailPage : function(component, event, helper) {
        var ChatterGroupObject = component.get("v.ChatterGroup");
        console.log('CP group iterator group id: '+ChatterGroupObject.groupId);
    	var navEvt = $A.get("e.force:navigateToSObject");
    	navEvt.setParams({
     	 "recordId": ChatterGroupObject.groupId
    	});
    	navEvt.fire();
	},
})