({
    showMyToast: function(component, helper, type, message) {
		var toastEvent = $A.get("e.force:showToast");
		var mode = 'dismissible';
		if (type == 'error' || type == 'warning') {
			mode = 'sticky';
		}
		toastEvent.setParams({
			type: type,
			mode: mode,
			message: message
		});
		toastEvent.fire();
	}
});