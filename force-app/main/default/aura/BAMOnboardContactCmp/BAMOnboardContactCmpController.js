/**
 * 2020-05-27 - Nathan Franklin - Included the search billing account selector table and fixed some minor UI bugs
 * 2023-07-08 - Mahesh Parvathaneni - Updated the appState to include the billing accounts
 * 2024-02-16 - Jacob.Isaac@auspost.com.au - Added Consignment Searching option in Merchant Portal - REQ2982613
 */
({
	onInitLoad : function(component, event, helper) {

		var contactId = component.get('v.contactId');

		console.debug('BAM OnboardContactComponent Init');
		// load for contact
		var actionInit = component.get("c.loadInitialState");
		var objParams = {
			"contactId": contactId
		};
		actionInit.setParams(objParams);
		actionInit.setCallback(this, function (response) {

			if (response.getState() == "SUCCESS") {
				var objResponse = response.getReturnValue();
				console.debug('OnboardContactComponent::loadInitialState');
				console.debug(objResponse);

				var objContact = objResponse.contact;

				if (objContact) {
					// set the contact object
					component.set('v.contactObj', objContact);

					// parse the static data
					helper.parseApplications(component,
						objResponse.applications,
						objResponse.contactApplications,
						objResponse.contactRolesPerApplication,
						objResponse.billingAccountsByApplication);

					new Promise($A.getCallback(function (result) {
						setTimeout($A.getCallback(function () {
							helper.initBillingAccountsVisibility(component);
						}), 100);
					}));

					component.set('v.showSpinner', false);
				}
				else {
					console.debug('OnboardContactComponent::loadInitialState Response has no Contact', objResponse);
					alert(objResponse.message);
				}
			}
			else if (response.getState() == "ERROR")
			{
				var errors = response.getError();
				console.debug('OnboardContactComponent::loadInitialState Response was ERROR', errors);
				alert(errors);
			}
		});
		$A.enqueueAction(actionInit);
	}

	, onSelectRole:function(component, event, helper)
	{
		//console.log('onSelectRole:' + event.getSource().get("v.value"));
		let idRole = event.getSource().get("v.value");
		helper.updateBillingAccountsVisibility(component, idRole);
	}

	, onChangeViewAllConsignment:function(component, event, helper){
		let viewAllConsignment = event.getSource().get("v.checked");
		helper.updateBSPCanViewAllConsignments(component,viewAllConsignment);
	}	
	// placeholder
	, onChangeBillingAccount:function(component, event, helper) {

	}

	// , onChangeBillingAccounts:function(component, event, helper)
	// {
	// 	const appId = event.getParam('applicationId');
	// 	const selectedBillingAccountIds = event.getParam('selected');
	// 	console.log(selectedBillingAccountIds);
	//
	// 	helper.setSelectedBillingAccounts(component, appId, selectedBillingAccountIds);
	// }

	, onClickProvision:function(component, event, helper)
	{
		//console.debug('BAM Onboard Contact:: onClickProvision');
		helper.saveProvisionState(component);
	}

	, onClickDeprovision:function(component, event, helper)
	{
		var appId = event.getSource().get("v.value");

		//console.warn('about to delete application Id:' + appId);
		var appName = helper.getApplicationNameById(component, appId);

		var confirmDelete = confirm('You are about to remove their access from ' + appName +'. \nClick OK to confirm');
		if(confirmDelete)
		{
			helper.saveDeprovision(component, appId);
		}

	}

	, handleCancelRequestClick: function(component, event, helper) {
		component.find('auraRequestCancellationModal').triggerModal();
	}

	, handleModalEvent: function(component, event, helper) {
		var a = event.getSource();
		var componentSourceId = a.getLocalId();
		var eventType = event.getParam("type");

		if(componentSourceId == 'auraRequestCancellationModal' && eventType == 'OK') {
			helper.submitCancellationRequest(component);
		}
	}
})