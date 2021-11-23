({
    /**
    *  Initializing
    */
    doInit: function(component, event, helper){
        component.set("v.refreshFlag", false);
        component.set("v.saved",false);
        component.set("v.showForm", true);
    },

    /**
    *   Load the default values for  on to the case detail section
    *   case status --> New
    *   Case purpose --> Depot Created
    */
    handleCreateLoad: function(component, event, helper) {
        var nameFieldValue1 = component.find("caseStatus").set("v.value", "New");
        var nameFieldValue2 = component.find("casePurpose").set("v.value", "Depot Created");
        component.set("v.refreshFlag", true);
        component.set("v.showForm", true);
    },

    /*
    *   Function to create a case and populate the values from consignment , if provided.
    *   Assignment rules needed to be triggered explicitily.
    */
    handleSubmit : function(component, event, helper) {
        event.preventDefault();
        var fields = event.getParam('fields');
        helper.onCaseSubmit(component, event, helper, fields);
    }
})