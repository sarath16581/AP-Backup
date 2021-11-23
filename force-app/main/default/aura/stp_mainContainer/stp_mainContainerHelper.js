({
    /**
    *   Display message on UI
    *   Usage :
    *   helper.showMyToast(component,helper,'info', 'test messaging toast info');
    *   helper.showMyToast(component,helper,'error', 'test messaging toast error');
    *   helper.showMyToast(component,helper,'success', 'test messaging toast success');
    *   helper.showMyToast(component,helper,'warning', 'test messaging toast warning');
    */
    showMyToast : function(component, helper,type,msg) {
        var toastEvent = $A.get("e.force:showToast");
        var mode = 'dismissible';
        if(type == 'error' || type == 'warning'){
            mode = 'sticky';
        }
        toastEvent.setParams({
            type : type,
            mode: mode,
            message: msg
        });
        toastEvent.fire();
    }
})