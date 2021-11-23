({
    doInit: function(cmp, event, helper) {        
        if(cmp.get('v.discoveryCategoryQuestions') == null){
            helper.fetchCategoryQuestions(cmp,'v.discoveryCategoryQuestions'); 
        }
        if(cmp.get('v.qualificationRecordId') != null && cmp.get('v.initialLoad')){
            var qualificationRecordId = cmp.get('v.qualificationRecordId');
            console.log('discoveryQuestion>>',cmp.get('v.discoveryCategoryQuestions'));
            cmp.set('v.discoveryCategoryQuestionsWithRelatedChild', cmp.get('v.discoveryCategoryQuestions'));
            helper.fetchExistingQualificationData(cmp);
        }
            
    },
    showPrductServices: function(cmp, event, helper) {
        helper.reportAllInValid(cmp, event);
        var allValid =  helper.checkAllValid(cmp, event)
        if(allValid){
            helper.setCurrentStepErrorStatus(cmp, false);
            var GenEvent = cmp.getEvent("genCmpEvent");
            GenEvent.setParam("NextCmpToLoad", 'ProductsSelection');
            GenEvent.setParam("qualificationRecordId", cmp.get('v.qualificationRecordId'));
            GenEvent.setParam("existingQualification", cmp.get('v.existingQualification'));
            GenEvent.setParam("discoveryCategoryQuestions", cmp.get('v.discoveryCategoryQuestions'));
            GenEvent.setParam("initialLoad", cmp.get('v.initialLoad'));
            GenEvent.setParam("editFlow", cmp.get('v.editFlow'));
            GenEvent.setParam("hasBgSalesPermissionSet", cmp.get('v.hasBgSalesPermissionSet'));
            GenEvent.setParam("isManualOpp", cmp.get('v.isManualOpp'));
            GenEvent.fire();
        }else{
            helper.setCurrentStepErrorStatus(cmp, true);
        }
    },
    saveResponse: function(cmp, event, helper) {
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
                var qualId = response.getReturnValue();;
                cmp.set('v.qualId',qualId);               
                cmp.set('v.isLoading',false);
                cmp.set('v.savedAsDraft',true);
                console.log('refreshing the component');
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
                            "message": "Please make sure you have entered the services data to submit a Qualification."
                        });
                        toastEvent.fire();
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);

    },
    handleRelatedQuestionEvent : function(cmp, evt, helper){
        console.log('Inside handle related question event');
        var ParentQuestionUniqueKey = evt.getParam('ParentQuestionUniqueKey');
        var relatedQuestionsVar = evt.getParam('relatedQuestions');
        var relatedResponseIds = evt.getParam('relatedResponseIds');
        var questionsVar = [];
        var originalQuestionsMap = new Map();
        var relatedQuestionsMap = new Map();
        console.log('relatedQuestionsVar',relatedQuestionsVar);
        console.log('relatedResponseIds',relatedResponseIds);
        cmp.get('v.discoveryCategoryQuestions').forEach(elementVar =>{
            originalQuestionsMap.set(elementVar.uniqueKey, elementVar);
        })
        relatedQuestionsVar.forEach(elemVar =>{            
            if(relatedQuestionsMap.has(elemVar.parentUniqueKey)){
                let questionTemp = [];
                questionTemp = relatedQuestionsMap.get(elemVar.parentUniqueKey);                
                questionTemp.push(elemVar);
                relatedQuestionsMap.set(elemVar.parentUniqueKey, questionTemp);
            }else{
                let questionTemp = [];
                questionTemp.push(elemVar);
                relatedQuestionsMap.set(elemVar.parentUniqueKey, questionTemp);
            }
            
        })
        for(var key of originalQuestionsMap.keys()){
            var qVar = originalQuestionsMap.get(key);
            if(qVar.relatedResponseId != null){
                if(relatedResponseIds.has(qVar.relatedResponseId)){
                    questionsVar.push(qVar);
                }else if(qVar.parentUniqueKey != ParentQuestionUniqueKey){
                    questionsVar.push(qVar);
                }
            }else{
                questionsVar.push(qVar);
            }
            
            //console.log('key>>>',key);
            if(relatedQuestionsMap.has(key)){
                var relatedQuestionsTemp = relatedQuestionsMap.get(key);
                relatedQuestionsTemp.forEach(e =>{
                    if(!originalQuestionsMap.has(e.uniqueKey)){
                        questionsVar.push(e);
                    }
                })
                
            }
        }
        console.log('questionsVar>>>>',questionsVar);
        
        if(questionsVar.length >0){
            cmp.set('v.discoveryCategoryQuestions', questionsVar);
        }
    }
    
})