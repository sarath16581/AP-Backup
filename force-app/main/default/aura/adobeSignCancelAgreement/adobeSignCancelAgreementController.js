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
						cmp.set("v.errMessage", errors[0].message);
					}
				} else {
					console.log("Unknown error");
				}
			}
		});
		$A.enqueueAction(action);
	},

	doOk: function(cmp, event, helper) {
		var myPageRef = cmp.get("v.pageReference");
		var masterId = myPageRef.state.c__masterId;
		var navService = cmp.find('navService');
		var pageReference = {
			type: 'standard__recordPage',
			attributes: {
				recordId: masterId,
				objectApiName: 'Apttus__APTS_Agreement__c',
				actionName: 'view'
			}
		};
		navService.navigate(pageReference);
	}
})