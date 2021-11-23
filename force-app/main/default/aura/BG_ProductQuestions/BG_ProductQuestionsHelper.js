({
    fetchCategoryQuestions : function(cmp) {
        var action = cmp.get('c.getCategoryTypeQuestions');//cmp.get("v.apexCaseCreationFunction")
        action.setParams({"categoryName" : cmp.get("v.product"), "recordIdStr" : cmp.get("v.recordId")});
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var questions = response.getReturnValue();
                var existingQualifications = cmp.get('v.existingQualification');
                var actualQuestionWithoutChild = [];
                questions.forEach(question =>{
                    if(!question.relatedResponseId){
                        actualQuestionWithoutChild.push(question);
                    }
                })
                cmp.set("v.productQuestionsWithoutChild", actualQuestionWithoutChild);
               if(existingQualifications){ 
                 var updatedQuestion =  this.updateAnswers(cmp, existingQualifications, questions);
                }else{
                    cmp.set("v.productQuestions", actualQuestionWithoutChild);
                    cmp.set("v.selectedProductsQuestions."+cmp.get('v.product'),actualQuestionWithoutChild);
                }
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
    updateAnswers:function(cmp, existingQualifications, questions){
        var existingQualificationsMap = new Map();
        var estimatedRevenue ;
        var note;
        var updateEstimateAndNote = false;
        existingQualifications.forEach(qualification =>{
            existingQualificationsMap.set(qualification.Question_Unique_Key__c, qualification);
        })
        var finalQuestionList = [];
        questions.forEach(ques =>{
            if(existingQualificationsMap.has(ques.uniqueKey)){
                if(existingQualificationsMap.get(ques.uniqueKey).Response__c != null){
                    ques.selectedAnswer = existingQualificationsMap.get(ques.uniqueKey).Response__c ; 
                }else if(existingQualificationsMap.get(ques.uniqueKey).Response_Date__c != null){
                    ques.selectedAnswer = existingQualificationsMap.get(ques.uniqueKey).Response_Date__c ; 
                }else if(existingQualificationsMap.get(ques.uniqueKey).Response_Multiline__c != null){
                    ques.selectedAnswer = existingQualificationsMap.get(ques.uniqueKey).Response_Multiline__c ; 
                }else if(existingQualificationsMap.get(ques.uniqueKey).Response_Number__c != null){
                    ques.selectedAnswer = existingQualificationsMap.get(ques.uniqueKey).Response_Number__c ; 
                }else if(existingQualificationsMap.get(ques.uniqueKey).Response_Percent__c != null){
                    ques.selectedAnswer = existingQualificationsMap.get(ques.uniqueKey).Response_Percent__c ; 
                }else if(existingQualificationsMap.get(ques.uniqueKey).PostCode_Mapping__c != null){
                    var postCodeId = existingQualificationsMap.get(ques.uniqueKey).PostCode_Mapping__c;
                    var postCodeName = existingQualificationsMap.get(ques.uniqueKey).PostCode_Mapping__r.Name;
                    var existingAnswer = {
                        Id : postCodeId,
                        Name :postCodeName
                    };
                    ques.selectedAnswer = existingAnswer;
                    ques.selectedAnswerLabel= postCodeName;
                }

                if(existingQualificationsMap.get(ques.uniqueKey).Qualification_Category_Detail__r.Selected_Category__c != "Discovery"){               
                    estimatedRevenue = existingQualificationsMap.get(ques.uniqueKey).Qualification_Category_Detail__r.Category_Estimate__c;
                    note = existingQualificationsMap.get(ques.uniqueKey).Qualification_Category_Detail__r.Notes__c;
                    updateEstimateAndNote = true;
                }
                finalQuestionList.push(ques);
            }
        })
        if(finalQuestionList.length > 0){
            cmp.set("v.selectedProductsQuestions."+cmp.get('v.product'),finalQuestionList);            
            cmp.set("v.productQuestions", finalQuestionList);
        }else{
            cmp.set("v.selectedProductsQuestions."+cmp.get('v.product'),cmp.get("v.productQuestionsWithoutChild"));            
            cmp.set("v.productQuestions", cmp.get("v.productQuestionsWithoutChild"));
        }

        
        if(updateEstimateAndNote){
            cmp.set("v.estimatedRevenue",estimatedRevenue);
            cmp.set("v.notes",note);
            cmp.set("v.selectedProductsQuestions."+cmp.get('v.product')+".revenue",estimatedRevenue);
            cmp.set("v.selectedProductsQuestions."+cmp.get('v.product')+".notes",note);
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
    checkOpportunityIsConverted : function(cmp) {
        var action = cmp.get('c.isOpportunityConverted');
        action.setParams({ "recordId" : cmp.get("v.recordId")});
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var showEstimatedRevenue = response.getReturnValue();
                cmp.set('v.showEstimatedRevenue',showEstimatedRevenue);
                
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
    }
})