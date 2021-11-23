({
    recSelected : function(component, event, helper){
        var target = event.target;
        var compEvent = component.getEvent("recSelectedEvent");
        compEvent.setParams({
            "label" : target.getAttribute("data-selected-label"),
            "value" : target.getAttribute("data-selected-value")
        });
        compEvent.fire();
    },
    fetchRecords : function(component, event, helper){
        component.set("v.Spinner",true);
        if(component.get("v.searchString").length > 1){
            var action = component.get("c.getRecordforAlllookups");
            action.setParams({
                "objectName" : component.get("v.objectAPIName"),
                "recLimit" : component.get("v.recLimit"),
                "searchString" : component.get("v.searchString"),
                "searchObject" : component.get("v.searchObject")
            });
            action.setCallback(this, function(response){
                component.set("v.sObjectList",response.getReturnValue());
                component.set("v.Spinner",false);
            });
            $A.enqueueAction(action);
        }
        else{
            component.set("v.Spinner",false);
            component.set("v.sObjectList",null);
        }
        
    }
})