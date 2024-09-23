/**
 * @description Aura wrapper to navigate to bulk edit screen
 * This aura wrapper is required to be put in an url action as LWC is not addressable
 * @author Harry Wang
 * @date 2023-05-09
 * @group Controller
 * @changelog
 * 2023-05-09 - Harry Wang - Created
 * 2023-10-17 - Bharat Patel - Updated onPageReferenceChange(), related to STP-9640 implementation
   2024-02-15 - Ken McGuire, Added link to revenue report 
*/
({
	onPageReferenceChange: function(cmp, event, helper) {
		let myPageRef = cmp.get("v.pageReference");
		let id = myPageRef.state.c__oppId;
		cmp.set("v.recordId", id);
				
		let proposalID = myPageRef.state.c__proposalId;
		cmp.set("v.proposalId", proposalID);

		let isST = myPageRef.state.c__isST;
		cmp.set("v.isST", isST);

		let isManualContract = myPageRef.state.c__isManualContract == undefined ? 'No': myPageRef.state.c__isManualContract;
		cmp.set("v.isManualContract", isManualContract);

		let isAmend = myPageRef.state.c__isAmend  == undefined ? 'No': myPageRef.state.c__isAmend;
		cmp.set("v.isAmend", isAmend);

		let isRenew = myPageRef.state.c__isRenew == undefined ? 'No': myPageRef.state.c__isRenew;
		cmp.set("v.isRenew", isRenew);

		var action = cmp.get("c.getOpportunity");
		action.setParams({oppId: cmp.get("v.recordId")});
		cmp.set("v.loading", true);
		action.setCallback(this, function(response) {
			cmp.set("v.loading", false);
			var state = response.getState();
			if (state === "SUCCESS") {
				var result = response.getReturnValue();
				if (result) {
					cmp.set("v.oppRecord", result);
				} else {
					helper.showMyToast(cmp,helper,'error', "Unknown Error");
				}
			} else if (state === "ERROR") {
				var errors = response.getError();
				if (errors) {
					if (errors[0] && errors[0].message) {
						helper.showMyToast(cmp,helper,'error', errors[0].message);
					}
				} else {
					helper.showMyToast(cmp,helper,'error', "Unknown Error");
				}
			}
		});
		$A.enqueueAction(action);
	},

	openRevenueReport : function(component, event, helper) {
		var oppId = component.get("v.recordId"); // Get the Opportunity Id
		var url = "/lightning/cmp/c__opcNavToRevenueReport?c__oppId=" + oppId;
		
		// Open the Aura component in a new tab
		window.open(url, '_blank');
	},

	recalculatePast12Revenue: function(component, event, helper) {
	    var toastEvent = $A.get("e.force:showToast");
		var action = component.get("c.recalculateRevenue");
		action.setParams({oppId: component.get("v.recordId")});
		component.set("v.loading", true);
		action.setCallback(this, function(response) {
		    component.set("v.loading", false);
			var state = response.getState();
			if (state === "SUCCESS") {
			    var result = response.getReturnValue();
			    if (result) {
			        window.location.reload();
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
 	},

});