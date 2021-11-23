/*
 * @description This is the main component to display the review and summary of the qualification questions before submitting them
 * @date 20/02/2020
 * @group Lead Qualification
 * @changelog
 * 2020-08-14 - jansi - Created
 * 2020-08-16 - arjun.singh@auspost.com.au - Modified to fetch primary product automatically based on specific business rules
 */
({
    submitResponse: function(cmp) {
    var leadRecordId;
    var opportunityRecordId;
    cmp.set('v.showErrorMessage',false);            
    if(cmp.get('v.editFlow')){
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
        if(discoveryRec.isRequired && (discoveryRec.selectedAnswer == "" || discoveryRec.selectedAnswer == null || discoveryRec.selectedAnswer == undefined)){
            cmp.set('v.showErrorMessage',true);
            return false;
        }
    });
    
    const originalselectedProductsQuestions = cmp.get("v.selectedProductsQuestions");
    const selectedProductsQuestionsTemp = JSON.parse(JSON.stringify(originalselectedProductsQuestions));

    var selectedProcts = cmp.get("v.selectedProducts") ;
    for(var key in selectedProductsQuestionsTemp){
        selectedProductsQuestionsTemp[key].forEach(productionQuestion =>{           
            if(productionQuestion.dataType == 'Postcode Lookup'){
                var selectedAnswer = productionQuestion.selectedAnswer;
                if(selectedAnswer != null){
                    var selecterAnswerId = selectedAnswer.Id;
                    productionQuestion.selectedAnswer = selecterAnswerId;
                }
            }
            if(selectedProcts.includes(key)){
                var productRevenue = cmp.get('v.selectedProductsQuestions.'+key+'.revenue');
                if((productionQuestion.isRequired && (productionQuestion.selectedAnswer == "" || productionQuestion.selectedAnswer == null || productionQuestion.selectedAnswer == undefined)) || (!productRevenue && !cmp.get('v.isManualOpp'))){
                    cmp.set('v.showErrorMessage',true);
                    return false;
                }
            }
        })
    }
    if(cmp.get('v.showErrorMessage') == false){
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
                        "status":"Completed"
                        })
        
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var qualId = response.getReturnValue();
                cmp.set('v.qualId',qualId);
                this.showReadonlySummary(cmp);

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
    }
},
showReadonlySummary: function (cmp) {
    var GenEvent = cmp.getEvent("genCmpEvent");
    GenEvent.setParam("NextCmpToLoad", 'ReadOnlySummary');
    GenEvent.setParam("qualificationRecordId", cmp.get('v.qualId'));
    GenEvent.setParam("navigateFromViewButton", false);
    GenEvent.setParam("editFlow", true);
    GenEvent.setParam("hasBgSalesPermissionSet", cmp.get('v.hasBgSalesPermissionSet'));
    GenEvent.fire();
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
setCurrentStepErrorStatus : function (cmp, currentStepHasError) {
    cmp.set('v.hasErrorInCurrentStep', currentStepHasError);
},
/**
 * @description used to fetch the primary product based on business rules and update to lead 
 *              primary product field during lead qualification process.
 *
fetchPrimaryProduct : function (cmp) {
    let selectedProducts = cmp.get('v.selectedProducts');
    let selectedPrimaryProduct;
    let selectedProductsQuestion = cmp.get('v.selectedProductsQuestions');
    /**
     In case of single product selected, primary product will be as per below rule
      1.If selected product is startrack then primiary product will be startrack
      2.If selected product is MyPost Business then primiary product will be MyPost Business
      3.If selected product is not either startrack or MyPost Business then primary product will be  Australia Post - Parcel Services
     *
    console.log('selectedProducts>>',selectedProducts);
    if(selectedProducts.length === 1){ 
        if(selectedProducts == 'StarTrack'){
            selectedPrimaryProduct = 'Startrack';
        }else if(selectedProducts == 'MyPost Business'){
            selectedPrimaryProduct = 'MyPost Business';
        }else{
            selectedPrimaryProduct = 'Australia Post - Parcel Services';
        }
        cmp.set('v.selectedPrimaryProduct',selectedPrimaryProduct);
    }else{
        let estimatedValue;
        // get the estimated amount configured in setting
        let actionEstimate = cmp.get('c.getStrackTrackProductEstimatedRevenue');
        actionEstimate.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                estimatedValue = response.getReturnValue();
                if((selectedProducts.indexOf("StarTrack") > -1) && cmp.get('v.selectedProductsQuestions.StarTrack.revenue') >= estimatedValue) {
                    /* If more than one product is selected and one of them is startrack having estimatedrevenue greater than the configured one
                     then the primary product should be selected as startrack*                       
                    cmp.set('v.selectedPrimaryProduct','Startrack');
                }else if((selectedProducts.indexOf("StarTrack") > -1) && cmp.get('v.selectedProductsQuestions.StarTrack.revenue') < estimatedValue) {
                    /* If more than one product is selected and one of them is startrack having estimatedrevenue lesser than the configured one
                     then the primary product should be selected as per below rule
                       1. if two product is selected and other is MyPost business then primary product should be Strattrack.
                       2. If more than two product is selected then primary product should be  Australia Post - Parcel Services'
                     *
                    if((selectedProducts.indexOf("MyPost Business") > -1) && selectedProducts.length === 2){
                       // selectedPrimaryProduct = 'Startrack';
                        cmp.set('v.selectedPrimaryProduct','Startrack');
                    }else{
                        //selectedPrimaryProduct = 'Australia Post - Parcel Services';
                        cmp.set('v.selectedPrimaryProduct','Australia Post - Parcel Services');
                    }
                }else {
                    cmp.set('v.selectedPrimaryProduct','Australia Post - Parcel Services');
                }
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
        $A.enqueueAction(actionEstimate);
    }
    
},*/
})