({
    fetchCategoryQuestions : function(cmp, resultsSetAttribute) {
        var action = cmp.get('c.getCategoryTypeQuestions');
        action.setParams({"categoryName" : cmp.get("v.category"), "recordIdStr" : cmp.get("v.recordId")});
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var questions = response.getReturnValue();
                var actualQuestionWithoutChild = [];
                questions.forEach(question =>{
                    if(!question.relatedResponseId){
                        actualQuestionWithoutChild.push(question);
                    }
                })
                cmp.set(resultsSetAttribute, actualQuestionWithoutChild);
                cmp.set('v.discoveryCategoryQuestionsWithRelatedChild', questions);
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
    fetchExistingQualificationData : function(cmp) {
        var qualificationRecordList ;
        var action = cmp.get('c.getExistingQualificationDetails');        
        action.setParams({"qualificationRecordId" : cmp.get("v.qualificationRecordId")});
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                qualificationRecordList = response.getReturnValue();  
                this.setExstingAnswerToQuestionV1(cmp, qualificationRecordList);           
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
    },
    setExstingAnswerToQuestionV1: function(cmp, qualificationRecordList) {
        var qualificationMap = new Map();
        qualificationRecordList.forEach(qualificationRecord =>{
            if(qualificationRecord.Qualification_Category_Detail__r.Selected_Category__c === cmp.get("v.category")){
                var questionKey = qualificationRecord.Question_Unique_Key__c;
                qualificationMap.set(questionKey, qualificationRecord);
            }
        })
        var finalQuestionList = [];
        cmp.get("v.discoveryCategoryQuestionsWithRelatedChild").forEach(questionVar =>{
            var keyVar = questionVar.uniqueKey;
            if(qualificationMap.has(keyVar)){
                var existingAnswer; 
                if(qualificationMap.get(keyVar).Response_Number__c != null){
                    existingAnswer = qualificationMap.get(keyVar).Response_Number__c;
                }else if(qualificationMap.get(keyVar).Response_Date__c != null){
                    existingAnswer = qualificationMap.get(keyVar).Response_Date__c;
                }else if(qualificationMap.get(keyVar).Response__c != null){
                    existingAnswer = qualificationMap.get(keyVar).Response__c;
                }else if(qualificationMap.get(keyVar).Response_Multiline__c != null){
                    existingAnswer = qualificationMap.get(keyVar).Response_Multiline__c;
                }else if(qualificationMap.get(keyVar).Response_Percent__c != null){
                    existingAnswer = qualificationMap.get(keyVar).Response_Percent__c;
                }else if(qualificationMap.get(keyVar).PostCode_Mapping__c != null){
                    var postCodeId = qualificationMap.get(keyVar).PostCode_Mapping__c;
                    var postCodeName = qualificationMap.get(keyVar).PostCode_Mapping__r.Name;
                    existingAnswer = {
                        Id : postCodeId,
                        Name :postCodeName
                    };
                }
                questionVar.selectedAnswer = existingAnswer;
                finalQuestionList.push(questionVar);
            }
        })        
        cmp.set('v.existingQualification', qualificationRecordList);
        if(finalQuestionList.length > 0){
            cmp.set('v.discoveryCategoryQuestions', finalQuestionList);
        }  
    },    
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
                if(inputCmp != 'undefined'){
                    inputCmp.reportValidity();
                }
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
    showDiscoveryCmp1: function (cmp) {
        var GenEvent = cmp.getEvent("genCmpEvent");
        GenEvent.setParam("NextCmpToLoad", 'Discovery');
        GenEvent.setParam("qualificationRecordId", cmp.get('v.qualId'));
        GenEvent.setParam("navigateFromViewButton", false);
        GenEvent.setParam("editFlow", true);
        GenEvent.setParam("initialLoad", true);
        GenEvent.setParam("hasBgSalesPermissionSet", cmp.get('v.hasBgSalesPermissionSet'));
        GenEvent.setParam("isManualOpp", cmp.get('v.isManualOpp'));
        GenEvent.fire();
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