({
    checkAllValid:function(cmp, event){
        var inputCmpFields = cmp.find('field');
        var allValid;
        if(Array.isArray(inputCmpFields)){
            allValid = this.asArray(inputCmpFields).reduce(function (validSoFar, inputCmp) {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
            
        }else{
            inputCmpFields.reportValidity();
            allValid = inputCmpFields.checkValidity();
        }
        return allValid;
    } ,
    reportAllInValid:function(cmp, event){
        var inputCmpFields = cmp.find('field');
        if(Array.isArray(inputCmpFields)){
            var allValid = this.asArray(inputCmpFields).reduce(function (validSoFar, inputCmp) {
                inputCmp.reportValidity();
            }, true);
        }else{
            inputCmpFields.reportValidity();
        }
    } ,
    asArray: function(x) {
        if (Array.isArray(x)) return x;
        else return x ? [x] : [];
    },
    setCurrentStepErrorStatus : function (cmp, currentStepHasError) {
        cmp.set('v.hasErrorInCurrentStep', currentStepHasError);
    },
    checkCustomValidations:function(cmp, event){
        var allValid = true;
        var selectedProducts = cmp.get('v.selectedProducts');
        for(var i=0; i<selectedProducts.length ; i++){
            //--If Tab is not loaded then showing error
            if(cmp.get("v.selectedProductsQuestions."+selectedProducts[i]) == null ){
                //&&  cmp.get("v.selectedProductsQuestions."+selectedProducts[i]+".revenue") == null && cmp.get("v.selectedProductsQuestions."+selectedProducts[i]+".notes") == null
                allValid = false;
                break;
            }
        }
        return allValid;
    },
    fetchQualificationInformation: function(cmp) {
        var qualificationRecordList ;
        var action = cmp.get('c.getExistingQualificationDetails');        
        action.setParams({"qualificationRecordId" : cmp.get("v.qualificationRecordId")});
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
               var qualRecord = response.getReturnValue();  
               cmp.set('v.existingQualification',qualRecord);
            }
            else if (response.getState() == "INCOMPLETE") {
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
    }
})