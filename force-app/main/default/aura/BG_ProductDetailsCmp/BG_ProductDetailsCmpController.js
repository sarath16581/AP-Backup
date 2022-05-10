({
    showPrductServices : function(cmp, event, helper) {
        //-- fire event to show product section
        var GenEvent = cmp.getEvent("genCmpEvent");
        GenEvent.setParam("NextCmpToLoad", 'ProductsSelection');
        GenEvent.setParam("editFlow", cmp.get('v.editFlow'));
        GenEvent.setParam("hasBgSalesPermissionSet", cmp.get('v.hasBgSalesPermissionSet'));
        GenEvent.setParam("existingQualification", cmp.get('v.existingQualification'));
        GenEvent.setParam("qualificationRecordId", cmp.get('v.qualificationRecordId'));
        GenEvent.setParam("discoveryCategoryQuestions", cmp.get('v.discoveryCategoryQuestions'));
        GenEvent.setParam("isManualOpp", cmp.get('v.isManualOpp'));
        GenEvent.fire();
    },
    showReview : function(cmp, event, helper) {
        helper.reportAllInValid(cmp, event);
        var allValid =  helper.checkAllValid(cmp, event) ;
        var validateCmp = cmp.find("validateCmp");
        var passValidation = validateCmp.validateResponse(cmp);
        // Call validation component to check if input is valid against validation configuration
        if(passValidation.status === false){
            helper.setCurrentStepErrorStatus(cmp, true);
            cmp.set('v.showErrorMessage', true);
            cmp.set('v.errorMessage', passValidation.errorMsg);
            return;
        }

        if(allValid){
            helper.setCurrentStepErrorStatus(cmp, false);
            cmp.set('v.showErrorMessage', false);
            var GenEvent = cmp.getEvent("genCmpEvent");
            GenEvent.setParam("NextCmpToLoad", 'ReviewAndEdit');
            GenEvent.setParam("editFlow", cmp.get('v.editFlow'));
            GenEvent.setParam("hasBgSalesPermissionSet", cmp.get('v.hasBgSalesPermissionSet'));
            GenEvent.setParam("existingQualification", cmp.get('v.existingQualification'));
            GenEvent.setParam("qualificationRecordId", cmp.get('v.qualificationRecordId'));
            GenEvent.setParam("discoveryCategoryQuestions", cmp.get('v.discoveryCategoryQuestions'));
            GenEvent.setParam("isManualOpp", cmp.get('v.isManualOpp'));
            GenEvent.fire();
        }else{
            helper.setCurrentStepErrorStatus(cmp, true);
            cmp.set('v.showErrorMessage', true);
        }
    },
    saveResponse: function(cmp, event, helper) {
        cmp.set('v.isLoading',true);
        cmp.set('v.isLoading',true);
        var leadRecordId;
        var opportunityRecordId;
        if(cmp.get('v.existingQualification') != null){
            var existingQualification = cmp.get('v.existingQualification');
            if(existingQualification[0].Qualification_Category_Detail__r.Qualification__r.Lead__c != null){
                leadRecordId = existingQualification[0].Qualification_Category_Detail__r.Qualification__r.Lead__c;
            }else if(existingQualification[0].Qualification_Category_Detail__r.Qualification__r.Opportunity__c != null){
                opportunityRecordId = existingQualification[0].Qualification_Category_Detail__r.Qualification__r.Opportunity__c;
            }
        }else{
            var recordId = cmp.get("v.recordId");
            if(recordId.startsWith('006')){
                opportunityRecordId = cmp.get("v.recordId"); 
            }else if(recordId.startsWith('00Q')){                 
                leadRecordId = cmp.get("v.recordId"); 
            }
            
        }
        const originaldiscoveryCategoryQuestions = cmp.get("v.discoveryCategoryQuestions");
        const discoveryQuestionTemp = JSON.parse(JSON.stringify(originaldiscoveryCategoryQuestions));

        discoveryQuestionTemp.forEach(discoveryRec =>{ 
            if(discoveryRec.dataType == 'Postcode Lookup'){
                var selectedAnswer = discoveryRec.selectedAnswer;
                if(selectedAnswer != null){
                    var selecterAnswerId = selectedAnswer.Id;
                    discoveryRec.selectedAnswer = selecterAnswerId;
                }
            }
        });
        const originalselectedProductsQuestions = cmp.get("v.selectedProductsQuestions");
        const selectedProductsQuestionsTemp = JSON.parse(JSON.stringify(originalselectedProductsQuestions));

        for(var key in selectedProductsQuestionsTemp){
            selectedProductsQuestionsTemp[key].forEach(productionQuestion =>{           
                if(productionQuestion.dataType == 'Postcode Lookup'){
                    var selectedAnswer = productionQuestion.selectedAnswer;
                    if(selectedAnswer != null){
                        var selecterAnswerId = selectedAnswer.Id;
                        productionQuestion.selectedAnswer = selecterAnswerId;
                    }
                }
            })
        }  

        var totalEstimates = 0;
        var allProductsList =[];
        var selectedProducts = cmp.get('v.selectedProducts');
        for(var i=0;i<selectedProducts.length;i++){
            var procuct = {
                "productName": selectedProducts[i],
            }; 
            allProductsList.push( cmp.get('v.selectedProductsQuestions.'+selectedProducts[i]));
            var revenue = {
                "revenue": cmp.get('v.selectedProductsQuestions.'+selectedProducts[i]+'.revenue')
            };
            cmp.set('v.productEstimateMap.'+selectedProducts[i]+'.revenue',
                    cmp.get('v.selectedProductsQuestions.'+selectedProducts[i]+'.revenue'));
            cmp.set('v.productNotesMap.'+selectedProducts[i]+'.notes',
                    cmp.get('v.selectedProductsQuestions.'+selectedProducts[i]+'.notes'));
            var temp =  parseInt(cmp.get('v.selectedProductsQuestions.'+selectedProducts[i]+'.revenue'));
            totalEstimates = totalEstimates + temp;
            var notes = {
                "notes": cmp.get('v.selectedProductsQuestions.'+selectedProducts[i]+'.notes')
            }; 
        }
        cmp.set('v.summaryProducts',allProductsList);
        cmp.set('v.totalEstimatedRevenue',totalEstimates);
        var action = cmp.get('c.submitResponse');        
        action.setParams({ "leadId" :leadRecordId,
                          "opportunityId" : opportunityRecordId,
                          "disCoveryQuestion" : JSON.stringify(discoveryQuestionTemp),         
                          "selectedProducts": JSON.stringify(cmp.get("v.selectedProducts")),
                          "selectedProdQuestionsMap":selectedProductsQuestionsTemp,
                          "productEstimateMap":cmp.get("v.productEstimateMap"),
                          "productNotesMap":cmp.get("v.productNotesMap"),
                          "totalEstimatedRevenue":cmp.get("v.totalEstimatedRevenue"),
                          "summaryNotes":cmp.get("v.summaryNotes"),
                          "primaryProduct":cmp.get("v.selectedPrimaryProduct"),
                          "existingQualification":JSON.stringify(cmp.get("v.existingQualification")),
                          "status":"In Progress"
                         });
        
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var qualId = response.getReturnValue();
                cmp.set('v.qualId',qualId); 
                cmp.set('v.isLoading',false);
                cmp.set('v.savedAsDraft',true);
                cmp.set('v.qualificationRecordId',qualId);
                cmp.get('v.initialLoad',true);
                helper.fetchQualificationInformation(cmp);
                $A.get('e.force:refreshView').fire();
  
            }
            else if (response.getState() == "INCOMPLETE") {
                console.log("Response Incomplete");
            }else if (response.getState() == "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type":"error",
                            "title": "ERROR",
                            "message": "Please make sure you have entered the products data to submit a Qulification."
                        });
                        toastEvent.fire();
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);

    }
})