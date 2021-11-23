({
    /**
    * get the recordTypeId for Delivery Enquiry Case RecordType
    */
    getDERecordtypeId : function(component, event, helper){

        var fetchRecordtypeAction = component.get("c.getRecordTypeId");
        fetchRecordtypeAction.setCallback(this, function (response) {
           var state = response.getState();
           if(state == 'SUCCESS') {
               // set case recordTypeId
               component.set('v.caserecordTypeId', response.getReturnValue());
           }
        });
        $A.enqueueAction(fetchRecordtypeAction);
        component.set('v.showForm', true);
    }

})