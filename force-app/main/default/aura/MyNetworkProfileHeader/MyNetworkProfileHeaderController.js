({  
	doInit : function(component, event, helper) {
   	 helper.getLocalList(component);
	},
    
    homeClick : function(component) {
		window.location = "/myNetwork/s/";
	},

    profileClick : function(component) {
		var action = component.get("c.myProfileUrl");
        action.setCallback(this, function(response) {
            window.location = response.getReturnValue();
        });
        $A.enqueueAction(action);
	},
    
    logoutClick : function(component) {
		var action = component.get("c.myLogoutUrl");
        action.setCallback(this, function(response) {
            console.log(response.getReturnValue());
            window.location = response.getReturnValue();
        });
        $A.enqueueAction(action);
	}
})