({
    doInit: function(component, event, helper) {
        var action = component.get("c.recalculateRevenue");
		action.setParams({oppId: component.get("v.recordId")});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				var result = response.getReturnValue();
				if (result) {
					component.set("v.oppLinesUpdated", result);
				} else {
					helper.showMyToast(component,helper,'error', "Unknown Error");
				}
			} else if (state === "ERROR") {
				var errors = response.getError();
				if (errors) {
					if (errors[0] && errors[0].message) {
						helper.showMyToast(component,helper,'error', errors[0].message);
					}
				} else {
					helper.showMyToast(component,helper,'error', "Unknown Error");
				}
			}
		});
		$A.enqueueAction(action);
        $A.get('e.force:refreshView').fire();
    },

    closeComp: function(component,event,helper){
        $A.get("e.force:closeQuickAction").fire();
        window.location.reload();
    }
 })