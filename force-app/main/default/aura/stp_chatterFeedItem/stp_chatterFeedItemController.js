({
    // Handle component initialization
    doInit : function(component, event, helper) {
        //Call an apex method to get feed item wrapper for the task
		var action = component.get("c.getFeedItemList");		
        action.setParams({
            "taskId" : component.get("v.taskReference")
        });
        action.setCallback(this, function(response) {
            if(response.getState() == 'SUCCESS'){
                console.log(response.getReturnValue());
                component.set("v.feedItemList",response.getReturnValue());
            } else {
            	var errors = response.getError();
				console.log('Error at feed item retrieval '+errors[0].message);    
            }            
        });
		$A.enqueueAction(action);
    }

})