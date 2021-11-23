({
    fetchLoggedInUserCases : function(cmp) {
        var action = cmp.get("c.getLoggedInUserCaseList");
        // action.setStorable();
        
        action.setCallback(this, function(response) {
            cmp.set('v.isLoading', false)
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue() != null){
                    cmp.set('v.caseList',response.getReturnValue());
                }
            } else if (state === "INCOMPLETE") {
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },	
})