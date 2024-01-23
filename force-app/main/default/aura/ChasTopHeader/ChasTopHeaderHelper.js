({
    setLoggedInUserName : function(component) {
        // TODO
        /*var name = "Thomas S"
		// Get First Name
		if (/\s/.test(name)) {
			name = name.split(/\s/)[0];
		}
		cmp.set('v.loggedInUserName', name); */
        
        //-- 1. Query User Info from Server with storable action
        var action = component.get("c.getLoggedInUserInfo");
        //action.setStorable();
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnObj =  JSON.parse((JSON.stringify(response.getReturnValue())));
                //console.log('user info='+JSON.stringify(response.getReturnValue()));
                //-- 1.a Checking If User is authenticated
                if(returnObj["isUserAuthenticated"] == true){
                    
                    //--1.a.2 setting latest userInfo to wizard attribute
                    component.set('v.loggedInUserName', returnObj["userFirstName"]);
                    
                }
            }
            else if (state === "INCOMPLETE") {
                console.log("INCOMPLETE : Error from service Call");
            }
                else if (state === "ERROR") {
                    component.set('v.wizardData.caseCreationStatus', 'ERROR');
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            //-- Console log
                            if(component.get("v.debugMode")){
                                console.log("Error message: " + errors[0].message);
                            }
                        }
                    } else {
                        //-- Console log
                        if(component.get("v.debugMode")){
                            console.log("Unknown error");
                        }
                    }
                }
            
        });
        $A.enqueueAction(action);
    },

    getCommunityUrl : function(component) {
        var action = component.get("c.retrieveCommunityURL");
        //action.setStorable();
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.communityUrl', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})