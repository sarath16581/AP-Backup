/*
  * @author       : Dheeraj Mandavilli. dheeraj.mandavilli@auspost.com.au
  * @date         : 24/04/2021
  * @description  : Component used as wrapper for Sub Account Request Quick Action Button from Billing Account. It has following features
  *                 1. It invokes createSubAccounts LWC component.
  *                 2. It also contains validation checks on Billing Account
  @changelog
  2021-04-24    Dheeraj Mandavilli Created
  2023-08-18    Harry Wang Updated navigation to SubAccountsCreationWrapper
*/
({
	doInit: function(component,event,helper) {
		// Set the attribute value.
		// You could also fire an event here instead.
		component.set("v.isModalOpen", false);
		component.get("v.recordId");
		console.log('record Id:::',component.get("v.recordId"));
		var recID = component.get('v.recordId');
		var action = component.get('c.getBillingAccountDetails');
		// convert the selected record list into a JSON format and send to the Apex Controller
		action.setParams({ "billingAccountRecord" :recID});
		action.setCallback(this, function(response) {
			// declare toast event for display success/error message banner on salesforce page
			// var toastEvent = $A.get("e.force:showToast");

			if (response.getState() === "SUCCESS") {
				component.set('v.BillingAccount',response.getReturnValue());

				const delFlag = component.get("v.BillingAccount.SAP_marked_for_deletion__c");

				const sourceSystem = component.get("v.BillingAccount.Source_System__c");

				const typeVal = component.get("v.BillingAccount.Type__c");

				const payerAccVal = component.get("v.BillingAccount.PAYER_ACCOUNT_ID__c");

				const leaderAccVal = component.get("v.BillingAccount.LeaderAccount__c")

				if (delFlag === true){
					component.set("v.isModalOpen", true);
					component.set("v.failedErrMsg", 'This request does not meet the minimum criteria to create a sub-account or follower/offspring account. A sub-account or follower/offspring account cannot be created for a Billing Account marked for deletion.');
				} else if (sourceSystem == 'TEAM' && (leaderAccVal != null || payerAccVal != null)) {
					component.set("v.isModalOpen", true);
					component.set("v.failedErrMsg", "This request does not meet the minimum criteria to create a Follower/Offspring account. A Follower/Offspring account cannot be created for a Billing Account that is not a Leader.");
				} else if (sourceSystem == 'TEAM' && leaderAccVal == null && payerAccVal == null) {
					component.set("v.isModalOpen", false);
					helper.navigateToCreateSubAccountsCmp(component, 'true');
				} else if (sourceSystem == 'PeopleSoft'){
					component.set("v.isModalOpen", true);
					component.set("v.failedErrMsg", 'This request does not meet the minimum criteria to create a sub-account or follower/offspring account. A sub-account or follower/offspring account cannot be created for a Billing Account with Source System PeopleSoft.');
				} else if (payerAccVal != null) {
					component.set("v.isModalOpen", true);
					component.set("v.failedErrMsg", 'This request does not meet the minimum criteria to create a sub-account. A sub-account cannot be created from a sub-account.');
				} else if (typeVal != 'CUST') {
					component.set("v.isModalOpen", true);
					component.set("v.failedErrMsg", 'This request does not meet the minimum criteria to create a sub-account. A sub-account cannot be created for Billing Account Type Agency or Cash.');
				} else {
					component.set("v.isModalOpen", false);
					helper.navigateToCreateSubAccountsCmp(component, 'false');
				}
			}
		});
		$A.enqueueAction(action);
	},

	closePopUp : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
		$A.get('e.force:refreshView').fire();
	},

	openModal: function(component, event, helper) {
		// Set isModalOpen attribute to true
		component.set("v.isModalOpen", true);
	},

	closeModal: function(component, event, helper) {
		// Set isModalOpen attribute to false
		component.set("v.isModalOpen", false);
	}
})