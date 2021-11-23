({
    doInit : function(cmp, event, helper) {
        console.log('reach BG_QualifiInitCmp');
        if(cmp.get('v.qualificationRecordId')){
            cmp.set('v.qualificationRecordExists', true);
        }else{
            cmp.set('v.qualificationRecordExists', false);
        }
        var action = cmp.get('c.isClosedOpportunity');
        action.setParams({ "recordId" : cmp.get("v.recordId")});
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var isClosedOpportunity = response.getReturnValue();
                cmp.set("v.closedOpportunity", isClosedOpportunity);                
            }
            else if (response.getState() == "INCOMPLETE") {
                console.log("Response Incomplete");
            }else if (response.getState() == "ERROR") {
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
    showDiscovery : function(cmp, event, helper) {
        cmp.set('v.showErrorMessage',false);
        if(cmp.get("v.closedOpportunity")){
            cmp.set('v.showErrorMessage',cmp.get("v.closedOpportunity"));
        }else{
            var action = cmp.get("c.hasBGSalesPermissionSetAssigned");
            action.setCallback(this, function(response) {
                if (response.getState() == "SUCCESS") {
                    var hasBgSalesPermissionSetVar = response.getReturnValue();
                    console.log('hasBgSalesPermissionSetVar>>>>',hasBgSalesPermissionSetVar);
                    //-- fire event to show discovery section
    
                    var GenEvent = cmp.getEvent("genCmpEvent");
                    GenEvent.setParam("NextCmpToLoad", 'Discovery');
                    GenEvent.setParam("hasBgSalesPermissionSet", hasBgSalesPermissionSetVar);
                    GenEvent.fire();
                } else if (response.getState() == "INCOMPLETE") {
                    console.log("Incomplete request");
                } else if (response.getState() == "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                } else {
                    console.log("Unknown error");
                }
            });
            $A.enqueueAction(action);  
		}
        
    },
    viewQualification : function(cmp, event, helper) {
        var action = cmp.get("c.hasBGSalesPermissionSetAssigned");
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var hasBgSalesPermissionSetVar = response.getReturnValue();
                //-- fire event to show discovery section
                var GenEvent = cmp.getEvent("genCmpEvent");
                GenEvent.setParam("NextCmpToLoad", 'ReadOnlySummary');
                GenEvent.setParam("editFlow", true);
                GenEvent.setParam("navigateFromViewButton", true);
                GenEvent.setParam("qualificationRecordId", cmp.get('v.qualificationRecordId'));
                GenEvent.setParam("hasBgSalesPermissionSet", hasBgSalesPermissionSetVar);
                GenEvent.fire();
            } else if (response.getState() == "INCOMPLETE") {
                console.log("Incomplete request");
            } else if (response.getState() == "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log("Unknown error");
            }
        });
        $A.enqueueAction(action);          
        
    }
})