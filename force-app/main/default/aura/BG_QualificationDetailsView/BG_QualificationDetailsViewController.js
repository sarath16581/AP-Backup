({
    doInit : function(cmp, event, helper) { 
        helper.fetchQualificationDetails(cmp);
    },
    editQualification : function(cmp, event, helper) { 
        var GenEvent = cmp.getEvent("genCmpEvent");
        GenEvent.setParam("NextCmpToLoad", 'EditQualification');
        GenEvent.setParam("editFlow", cmp.get('v.editFlow'));
        GenEvent.setParam("initialLoad", cmp.get('v.editFlow'));
        GenEvent.setParam("qualificationRecordId", cmp.get('v.qualificationRecordId'));
        GenEvent.setParam("hasBgSalesPermissionSet", cmp.get('v.hasBgSalesPermissionSet'));
        GenEvent.setParam("isManualOpp", cmp.get('v.isManualOpp'));
        GenEvent.fire();
    },
    closeQualification : function(cmp, event, helper) { 
        var GenEvent = cmp.getEvent("genCmpEvent");
        GenEvent.setParam("NextCmpToLoad", 'initCmp');
        GenEvent.setParam("editFlow", cmp.get('v.editFlow'));
        GenEvent.setParam("initialLoad", cmp.get('v.editFlow'));
        GenEvent.setParam("qualificationRecordId", cmp.get('v.qualificationRecordId'));
        GenEvent.setParam("hasBgSalesPermissionSet", false);
        GenEvent.setParam("isManualOpp", cmp.get('v.isManualOpp'));
        GenEvent.fire();
    }
    
})