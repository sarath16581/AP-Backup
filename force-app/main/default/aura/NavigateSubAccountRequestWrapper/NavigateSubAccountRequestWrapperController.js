/*
  * @author       : Harry Wang
  * @date         : 2023-08-18
  * @description  : Component used as wrapper for Sub Account Request Navigation from Billing Account.
  *                 Either createTEAMFollowerOffspringRequest or createSubAccountsRequest is opened based on the value of isTeamRequest
  @changelog
  2023-08-18    Harry Wang - Created
*/
({
	doInit: function(component, event, helper) {
		const pageReference = component.get("v.pageReference");
		component.set("v.recordId", pageReference.state.c__recordId);
		component.set("v.initialLoad", pageReference.state.c__initialLoad);
		component.set("v.isTEAMRequest", pageReference.state.c__isTEAMRequest);
		component.set("v.isBillingAccount", pageReference.state.c__isBillingAccount);
	}
});