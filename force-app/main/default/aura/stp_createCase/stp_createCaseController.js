({
    /**
     *   Initialise the values,
     *   get delivery enquire recordType ID
     */
    setDefaults: function(component, event, helper) {
        component.set('v.consignmentNum', "");
        helper.getDERecordtypeId(component, event, helper);
    },

    /**
    *  Case create form pop up Modal
    *  components: modalCmp
    *  Passing stp_CaseRecordEditCmp to ModalCmp
    */
    onCaseCreateClick : function(component, event, helper){
        component.set("v.isCreate", true);
        component.set("v.refreshFlag", false);
        component.set("v.saved",false);
        var deRecordTypeId = component.get('v.caserecordTypeId');
        var wait = component.get('v.loadingSpinner');
        $A.createComponent(
            "c:stp_CaseRecordEditCmp",
            {
                "aura:id": "caseRecord",
                "caserecordTypeId" : deRecordTypeId,
                "loadingSpinner" : wait
            },
            function(newComponent, status, errorMessage){
                component.set('v.caseRecordEditFormCmp', newComponent);
            }
        );
    },

    /**
    *   Close the Modal and reset the values
    *
    */
    onModalEvent: function(component, event, helper) {
         component.set("v.isCreate", false);
         var eventType = event.getParam("type");
         if(eventType == 'CLOSE') {
             console.log('event :: '+ event.getParam("type"));
         }
     }
})