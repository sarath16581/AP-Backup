({

    doInit: function(cmp, event, helper) {
        var caseStatus = cmp.get('v.caseObj.Enquiry_Status__c');
        var colour = cmp.get('v.colourMap')[caseStatus];
        cmp.set('v.statusColour', colour);
    },

    navigateTorecordDetail: function(cmp, event, helper) {
        var caseRecordId = cmp.get('v.caseObj.Id');
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/case/" + caseRecordId + ""
        });
        urlEvent.fire();
    }
})