({
    onLoad : function(component, event, helper) {
        var action = component.get("c.getTemplateList");
        action.setCallback(this, function(response){
            component.set("v.rtypeList",response.getReturnValue());
        });
        $A.enqueueAction(action);
    },

    selectTemplate : function(component, event, helper){
        var selectDiv = document.getElementById('formElement');
        if(component.get("v.selectedTemplatedId") == undefined || component.get("v.selectedTemplatedId") == 'null'){
            $A.util.addClass(selectDiv, 'slds-has-error');
            component.set("v.showError",true);
        } else {
            component.set("v.templateSelected",false);
            component.set("v.templateSelected",true);
        }
    },

    chooseValue : function(component, event, helper){
        component.set("v.selectedTemplatedId",document.getElementById('templateSelect').value);
    }
});