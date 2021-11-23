({
    handleProdChange:function(cmp, event, helper) {
        var isValid = helper.validateProducts(cmp);
        if(isValid){
            helper.setProductSelectionErrorMessage(cmp, null);   cmp.set('v.prodErrorMessage', null);
            helper.setCurrentStepErrorStatus(cmp, false);
        }
    },
    showDiscovery: function(cmp, event, helper) {
        //-- fire event to show discovery section
        var GenEvent = cmp.getEvent("genCmpEvent");
        GenEvent.setParam("NextCmpToLoad", 'Discovery');
        GenEvent.setParam("initialLoad", 'false');
        GenEvent.setParam("editFlow", cmp.get('v.editFlow'));
        GenEvent.setParam("hasBgSalesPermissionSet", cmp.get('v.hasBgSalesPermissionSet'));
        GenEvent.setParam("qualificationRecordId", cmp.get('v.qualificationRecordId'));
        GenEvent.setParam("existingQualification", cmp.get('v.existingQualification'));
        GenEvent.setParam("discoveryCategoryQuestions", cmp.get('v.discoveryCategoryQuestions'));
        GenEvent.setParam("isManualOpp", cmp.get('v.isManualOpp'));
        GenEvent.fire();
    },
    showProductQuestions: function(cmp, event, helper) {
        var isValid = helper.validateProducts(cmp);
        if(isValid){
            cmp.set('v.prodErrorMessage', null);
            helper.setCurrentStepErrorStatus(cmp, false);
            var GenEvent = cmp.getEvent("genCmpEvent");
            GenEvent.setParam("NextCmpToLoad", 'ProductDetails');
            GenEvent.setParam("qualificationRecordId", cmp.get('v.qualificationRecordId'));
            GenEvent.setParam("existingQualification", cmp.get('v.existingQualification'));
            GenEvent.setParam("initialLoad", false);
            GenEvent.setParam("editFlow", cmp.get('v.editFlow'));
            GenEvent.setParam("hasBgSalesPermissionSet", cmp.get('v.hasBgSalesPermissionSet'));
            GenEvent.setParam("discoveryCategoryQuestions", cmp.get('v.discoveryCategoryQuestions'));
            GenEvent.setParam("isManualOpp", cmp.get('v.isManualOpp'));
            GenEvent.fire();
        }else{
            helper.setProductSelectionErrorMessage(cmp, '');
            cmp.set('v.prodErrorMessage', cmp.get('v.errorMessage'));
            helper.setCurrentStepErrorStatus(cmp, true);
            
        }
    },
})