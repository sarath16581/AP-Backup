({
    doInit : function(component, event, helper) {
        let defaultType = component.get('v.errorType');
        // fetch error messages from custom label
        if(defaultType == 'generic')
        {
            var genericError = $A.get("$Label.c.CompensationErrorSublabels");
            var nextSteps = component.find("nextSteps");
            nextSteps.set("v.value", genericError);
        }
        else
        {
            var systemError = $A.get("$Label.c.CompensationSystemErrorSubLabel");
            var nextSteps = component.find("nextSteps");
            nextSteps.set("v.value", systemError);
        }
    },
    backtoHome: function(component, event, helper) {
        window.open("https://helpandsupport.auspost.com.au/s",'_blank');
    }
    
    
})