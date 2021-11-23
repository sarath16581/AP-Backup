({
    fetchQualificationDetails : function(cmp) {
        
        var action = cmp.get('c.getQualificationSummaryDetails');
        action.setParams({ "qualId" : cmp.get("v.recordId")});
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var qulWrapper = response.getReturnValue();
                cmp.set("v.qualification", qulWrapper);
                this.checkQualificationEditAvailable(cmp, qulWrapper);
                
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
    checkQualificationEditAvailable: function(cmp, qulWrapper){
        var editDateString = $A.get("$Label.c.Guided_Qualification_Edit_Start_Date");
        var editDate = new Date(editDateString); 
        var hasClosedOpp = qulWrapper.oppIsClosed;

        var qualificateCreatedDate =   qulWrapper.createdDate;
        var qualificateCreatedDateVar = new Date(qualificateCreatedDate);
        if(qualificateCreatedDateVar > editDate && !hasClosedOpp){
            cmp.set('v.editAvailable', true);
        }else{
            cmp.set('v.editAvailable', false);
        }
    }
})