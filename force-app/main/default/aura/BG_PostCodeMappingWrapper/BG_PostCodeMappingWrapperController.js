({  
    doInit : function(component, event, helper) {
        var selectedPC = component.get('v.value');
        if(selectedPC){
            component.set('v.valueLabel',selectedPC.Name);
        }
    },
    searchResultSelectHandler : function(component, event, helper) {
        var postcodeVal = event.getParam('value');
        component.set('v.value',postcodeVal);
        component.set('v.valueLabel',postcodeVal.Name);
        
    }
})