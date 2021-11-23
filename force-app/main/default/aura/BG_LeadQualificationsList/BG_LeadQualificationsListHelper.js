({
	 fetchQualificationsList : function(cmp) {
        
        var action = cmp.get('c.getQualificationsList');//cmp.get("v.apexCaseCreationFunction")
        action.setParams({ "recordId" : cmp.get("v.recordId")});
        //action.setStorable();
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
              
                cmp.set("v.qualificationList", response.getReturnValue());
             
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

    checkOpportunityConverted : function(cmp) {
        console.log('checkOpportunityConverted---HERE');
        
        var action = cmp.get("c.isOpportunityConverted");
        action.setParams({ 
            recordId: cmp.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                console.log('response.getReturnValue()=>'+response.getReturnValue());
                let oppConvertStatus = response.getReturnValue();
                // CNA launched from manually created Opportunity
                if (oppConvertStatus == false){
                    cmp.set('v.isManualOpp', true);
                }
                // CNA launched from Lead or converted opportunity
                else{
                    cmp.set('v.isManualOpp', false);
                }
                console.log('isManualOpp=>'+ cmp.get('v.isManualOpp'));
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
    },
})