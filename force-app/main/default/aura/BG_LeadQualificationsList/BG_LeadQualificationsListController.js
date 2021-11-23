({
    doInit : function(cmp, event, helper) {
        cmp.set('v.leadId', cmp.get('v.recordId'));
        helper.fetchQualificationsList(cmp);
        helper.checkOpportunityConverted(cmp);
    },
    hideSummary: function(cmp, event, helper) {
       // cmp.set('v.selectedQualId', null);
    },
    closeModel: function(cmp, event, helper) {
        cmp.set('v.selectedQualId', null);
    },
})