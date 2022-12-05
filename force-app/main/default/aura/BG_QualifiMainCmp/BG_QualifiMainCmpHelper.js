({
    loadNextCmp : function(cmp, event) {
        var nextCmp = event.getParam('NextCmpToLoad');
        if(nextCmp == 'Discovery'){
            this.loadDiscoveryCmp(cmp, event);
        }else  if(nextCmp == 'ProductsSelection'){
             if(event.getParam('qualificationRecordId') != null && event.getParam('initialLoad')){            
                this.setExistingQualificationDetails(cmp, event);
            } 
            this.loadProductsSelectionCmp(cmp, event);
        }else  if(nextCmp == 'ProductDetails'){
            this.loadProductDetailsCmp(cmp, event);
        }else  if(nextCmp == 'ReviewAndEdit'){
            this.loadReviewAndEditCmp(cmp, event);
        }else  if(nextCmp == 'ReadOnlySummary'){
            this.loadReadOnlySummaryCmp(cmp, event);
        }else  if(nextCmp == 'EditQualification'){
            this.loadDiscoveryCmp(cmp, event);
        }else  if(nextCmp == 'initCmp'){
            this.loadInitCmp(cmp, event);
        }        
        else{
            alert('No next cmp is configure, please contact your Syastem Administrator.');
        }
 
    },
    setExistingQualificationDetails: function(cmp, event) {
        cmp.set('v.existingQualification',event.getParam('existingQualification'));
        cmp.set('v.discoveryCategoryQuestions',event.getParam('discoveryCategoryQuestions'));
        cmp.set('v.qualificationRecordId',event.getParam('qualificationRecordId'));

        var selectedProductsVar = [];
        var selectedProductsSet = new Set();
        if(cmp.get('v.existingQualification')){
            cmp.get('v.existingQualification').forEach(qualificationRecord =>{
                if(!selectedProductsSet.has(qualificationRecord.Qualification_Category_Detail__r.Selected_Category__c) && qualificationRecord.Qualification_Category_Detail__r.Selected_Category__c != 'Discovery' && qualificationRecord.Qualification_Category_Detail__r.Selected_Category__c != 'Operational Details' ){
                    selectedProductsSet.add(qualificationRecord.Qualification_Category_Detail__r.Selected_Category__c);
                    selectedProductsVar.push(qualificationRecord.Qualification_Category_Detail__r.Selected_Category__c);
                }
            })
            cmp.set('v.selectedProducts', selectedProductsVar);
        }

    },
     loadInitCmp: function(cmp, event) {
        var action = cmp.get("c.isOpportunityConverted");
        action.setParams({ 
            recordId: cmp.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                let oppConvertStatus = response.getReturnValue();
                // CNA launched from manually created Opportunity
                if (oppConvertStatus == false){
                    cmp.set('v.isManualOpp', true);
                }
                // CNA launched from Lead or converted opportunity
                else{
                    cmp.set('v.isManualOpp', false);
                }
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

        var compAttributes; 
        cmp.set('v.hasBgSalesPermissionSet', event.getParam('hasBgSalesPermissionSet'));
        if(cmp.get('v.initialLoad')){
            compAttributes ={
                "qualificationRecordId": cmp.getReference('v.recordId'),
                "initialLoad": cmp.get('v.initialLoad'),
                "hasBgSalesPermissionSet": event.getParam('hasBgSalesPermissionSet')
            };
            this.createCmp(cmp, event, cmp.get('v.discoveryCmpName'),compAttributes);
        }else{
            var qualificationRecordId;
            var action = cmp.get("c.getExistingResponseId");
            action.setParams({ 
                recordId: cmp.get('v.recordId')
            });
            action.setCallback(this, function(response) {
                if (response.getState() == "SUCCESS") {
                    qualificationRecordId = response.getReturnValue();
                    compAttributes = {
                        "qualificationRecordId" : qualificationRecordId,
                        "recordId": cmp.get('v.recordId'),
                        "hasBgSalesPermissionSet": event.getParam('hasBgSalesPermissionSet')
                    }
                    this.createCmp(cmp, event, cmp.get('v.initCmp'),compAttributes);
                    
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
    loadDiscoveryCmp: function(cmp, event) {
        cmp.set('v.editFlow', event.getParam('v.editFlow'));
        cmp.set('v.hasBgSalesPermissionSet', event.getParam('hasBgSalesPermissionSet'));
        cmp.set('v.discoveryCategoryQuestions', event.getParam('discoveryCategoryQuestions'));
        cmp.set('v.existingQualification', event.getParam('existingQualification'));
        var compAttributes = {
            "discoveryCategoryQuestions": cmp.getReference('v.discoveryCategoryQuestions'),
            "initialLoad": event.getParam('initialLoad'),
            "qualificationRecordId": event.getParam('qualificationRecordId'),
            "editFlow": event.getParam('editFlow'),
            "hasBgSalesPermissionSet": event.getParam('hasBgSalesPermissionSet'),
            "recordId": cmp.getReference('v.recordId'),
            "existingQualification": cmp.get('v.existingQualification'),
            "discoveryCategoryQuestions": cmp.get('v.discoveryCategoryQuestions'),
            "isManualOpp": cmp.get('v.isManualOpp')
        };
        this.createCmp(cmp, event, cmp.get('v.discoveryCmpName'),compAttributes);          
    },
    loadProductsSelectionCmp: function(cmp, event) {
        cmp.set('v.editFlow', event.getParam('v.editFlow'));
        cmp.set('v.hasBgSalesPermissionSet', event.getParam('hasBgSalesPermissionSet'));
        cmp.set('v.discoveryCategoryQuestions', event.getParam('discoveryCategoryQuestions'));
        cmp.set('v.existingQualification', event.getParam('existingQualification'));
        
        var compAttributes = {
            "selectedProducts": cmp.getReference('v.selectedProducts'),
            "productAndServicesList": cmp.getReference('v.productAndServicesList'),
            "qualificationRecordId": cmp.get('v.qualificationRecordId'),
            "existingQualification": cmp.get('v.existingQualification'),
            "editFlow": cmp.get('v.editFlow'),
            "hasBgSalesPermissionSet": cmp.get('v.hasBgSalesPermissionSet'),
            "discoveryCategoryQuestions":cmp.get('v.discoveryCategoryQuestions'),
            "isManualOpp": cmp.get('v.isManualOpp')
        };
        this.createCmp(cmp, event, cmp.get('v.productsSelectionCmpName'),compAttributes);
    },
    loadProductDetailsCmp: function(cmp, event) {
        cmp.set('v.qualificationRecordId',event.getParam('qualificationRecordId'));
        cmp.set('v.editFlow', event.getParam('v.editFlow'));
        cmp.set('v.hasBgSalesPermissionSet', event.getParam('hasBgSalesPermissionSet'));
        cmp.set('v.discoveryCategoryQuestions', event.getParam('discoveryCategoryQuestions'));
        var compAttributes = {          
            "selectedProducts": cmp.getReference('v.selectedProducts'),  
            "selectedProductRelatedQuestions": cmp.getReference('v.selectedProductRelatedQuestions'),
            "qualificationRecordId": cmp.get('v.qualificationRecordId'),
            "existingQualification": cmp.get('v.existingQualification'),
            "editFlow": cmp.get('v.editFlow'),
            "hasBgSalesPermissionSet": cmp.get('v.hasBgSalesPermissionSet'),
            "recordId": cmp.getReference('v.recordId'),
            "discoveryCategoryQuestions":cmp.get('v.discoveryCategoryQuestions'),
            "selectedProductsQuestions":cmp.getReference('v.selectedProductsQuestions'),
            "isManualOpp": cmp.get('v.isManualOpp')
        };
        this.createCmp(cmp, event, cmp.get('v.productDetailsCmpName'),compAttributes);
    },
    loadReviewAndEditCmp: function(cmp, event) {        
        cmp.set('v.editFlow', event.getParam('v.editFlow'));
        cmp.set('v.hasBgSalesPermissionSet', event.getParam('hasBgSalesPermissionSet'));
        cmp.set('v.existingQualification', event.getParam('existingQualification'));
        cmp.set('v.qualificationRecordId', event.getParam('qualificationRecordId'));
        cmp.set('v.discoveryCategoryQuestions', event.getParam('discoveryCategoryQuestions'));
        var compAttributes = {
            "discoveryCategoryQuestions": cmp.getReference('v.discoveryCategoryQuestions'),
            "summaryProducts": cmp.getReference('v.summaryProducts'),
            "totalEstimatedRevenue": cmp.getReference('v.totalEstimatedRevenue'),
            "summaryNotes": cmp.getReference('v.summaryNotes'),
            "selectedProducts": cmp.getReference('v.selectedProducts'),
            "selectedProductsQuestions": cmp.getReference('v.selectedProductsQuestions'),
            "selectedPrimaryProduct": cmp.getReference('v.selectedPrimaryProduct'),
            "recordId": cmp.getReference('v.recordId'),
            "productEstimateMap": cmp.getReference('v.productEstimateMap'),
            "productNotesMap": cmp.getReference('v.productNotesMap'),
            "qualId": cmp.getReference('v.qualId'),
            "editFlow": cmp.getReference('v.editFlow'),
            "existingQualification": cmp.getReference('v.existingQualification'),
            "hasBgSalesPermissionSet": cmp.get('v.hasBgSalesPermissionSet'),
            "isManualOpp": cmp.get('v.isManualOpp')
        };
        this.createCmp(cmp, event, cmp.get('v.reviewAndSummaryCmpName'),compAttributes);
    },
    loadReadOnlySummaryCmp: function(cmp, event) {
        cmp.set('v.editFlow', event.getParam('v.editFlow'));
        cmp.set('v.hasBgSalesPermissionSet', event.getParam('hasBgSalesPermissionSet'));
        var compAttributes = {
            "qualId": event.getParam('qualificationRecordId'),
            "qualificationRecordId": event.getParam('qualificationRecordId'),
            "editFlow": event.getParam('editFlow'),
            "navigateFromViewButton": event.getParam('navigateFromViewButton'),
            "hasBgSalesPermissionSet": event.getParam('hasBgSalesPermissionSet'),
            "hasBgSalesPermissionSet": cmp.get('v.hasBgSalesPermissionSet'),
            "isManualOpp": cmp.get('v.isManualOpp')
        };
        this.createCmp(cmp, event, cmp.get('v.ReadOnlySummaryCmpName'),compAttributes);
    },
    
    createCmp: function(cmp, event,cmpName, compAttributes) {
        $A.createComponent(
            cmpName,
            compAttributes,
            function(pageCmp,status, errorMessage){
                var body = cmp.get("v.body");
                cmp.set("v.body", [pageCmp]);
            }
        );
    }

})