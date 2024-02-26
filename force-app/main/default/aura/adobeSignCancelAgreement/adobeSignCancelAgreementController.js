({
	doInit: function(cmp, event, helper) {
		// Get the URL parameters
		var myPageRef = cmp.get("v.pageReference");
		var masterId = myPageRef.state.c__masterId;

		var action = cmp.get('c.autoRedirect'); 
		action.setParams({
							'referenceComponent' : 'AdobeSignApttusCancel',
							'masterId' : masterId,
							'attachmentIds' : null
						});
		action.setCallback(this, function(response) {
			if (response.getState() === "SUCCESS") {
				// cmp.set('v.auraTest', response.getReturnValue());
				console.log('response.getReturnValue() : ');
				console.log(response.getReturnValue());

				// Auto redirect to the Adobe Sign Agreement View Page
				var urlEvent = $A.get("e.force:navigateToURL");
				urlEvent.setParams({
					"url": response.getReturnValue().pageRef
				});
				urlEvent.fire();
			} 
			else if (response.getState() === "ERROR") {
				var errors = response.getError();
				if (errors) {
					if (errors[0] && errors[0].message) {
						console.log("Error message: " + errors[0].message);
						var toastEvent = $A.get("e.force:showToast");
						toastEvent.setParams({
							"type":"error",
							"title": "ERROR",
							"message": errors[0].message
						});
						toastEvent.fire();
					}
				} else {
					console.log("Unknown error");
				}
			}
		});
		$A.enqueueAction(action);
	}
})
