({
    onRecordIdChange : function(cmp, event, helper) {
        cmp.set('v.qualificationList',[]);
        cmp.set('v.leadId', cmp.get('v.recordId'));
        debugger;
        let leadId  = cmp.get('v.recordId');
        if(leadId != null && leadId.startsWith('00Q')){
            helper.fetchQualificationsList(cmp);
        } 
    }
})