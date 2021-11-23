/*
 * @description This is the main component to display the review and summary of the qualification questions before submitting them
 * @date 20/02/2020
 * @group Lead Qualification
 * @changelog
 * 2020-08-14 - jansi - Created
 * 2020-08-16 - arjun.singh@auspost.com.au - Modified to fetch primary product automatically based on specific business rules
 */
({
    doInit : function(cmp, event, helper) {
        var totalEstimates = 0;
        var allProductsList =[];
        var selectedProducts = cmp.get('v.selectedProducts');
        var summaryNote = cmp.get('v.existingQualification[0].Qualification_Category_Detail__r.Qualification__r.Notes__c');
        cmp.set('v.summaryNotes',summaryNote);
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
        //Adding a new method to calculate the primary product 
        //helper.fetchPrimaryProduct(cmp);
    },
	showProductDetails  : function(cmp, event, helper) {
        var GenEvent = cmp.getEvent("genCmpEvent");
        GenEvent.setParam("NextCmpToLoad", 'ProductDetails');
        GenEvent.setParam("editFlow", cmp.get('v.editFlow'));
        GenEvent.setParam("hasBgSalesPermissionSet", cmp.get('v.hasBgSalesPermissionSet'));
        GenEvent.setParam("discoveryCategoryQuestions", cmp.get('v.discoveryCategoryQuestions'));
        GenEvent.setParam("qualificationRecordId", cmp.get('v.qualificationRecordId'));
        GenEvent.setParam("existingQualification", cmp.get('v.existingQualification'));
        GenEvent.fire();
    },
    FinishAndShowReadOnlySummary : function(cmp, event, helper) {
        helper.reportAllInValid(cmp, event);
        var allValid =  helper.checkAllValid(cmp, event)
        if(allValid){
            helper.submitResponse(cmp);
        }else{
            helper.setCurrentStepErrorStatus(cmp, true);
        }
    },
})