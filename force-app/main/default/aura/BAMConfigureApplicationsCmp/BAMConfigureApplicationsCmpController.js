({
	doInit : function(component, event, helper) {

		component.set('v.showSpinner', true);
		// init load
		var accountId = component.get('v.accountId');

		if(!accountId)
		{
			alert('No Account Id provided');
			return;
		}

		var actionInit = component.get("c.getInitLoad");
		var objParams = {
			"accountId": accountId
		};
		actionInit.setParams(objParams);
		actionInit.setCallback(this, function (response) {
			if (response.getState() == "SUCCESS") {
				console.debug('BAM_assetCreation::getInitLoad');
				var objResponse = response.getReturnValue();
				console.debug(objResponse);

				var account = objResponse.account;
				if(!account)
				{
					console.error('Account not found for Id: ' + accountId);
				}
				else
				{
					component.set('v.account', account);

					// add contacts
					var arrContacts = objResponse.contacts;
					component.set('v.allContacts', arrContacts);
					helper.filterContacts(component);

					// add BAM Super Admins
                    var arrContactAdmins = objResponse.admins;
                    component.set('v.bamAdminContacts', arrContactAdmins);
				}

				// show a list of application-products
				var arrProducts = objResponse.products;
				helper.refreshProductsList(component, arrProducts);

				component.set('v.showSpinner', false);
			}
		});
		$A.enqueueAction(actionInit);
	}

	, onChangeStatus:function(component, event, helper)
	{
		component.set('v.enableButton', true);
	}

	, onClickUpdate:function (component, event, helper)
	{
		component.set('v.showSpinner', true);
		component.set('v.enableButton', false);

		// init load
		var accountId = component.get('v.accountId');
		var arrProducts = component.get('v.products');
		var actionUpdate = component.get("c.updateApplications");
		var objParams = {
			"accountId": accountId,
			"products": arrProducts
		};
		actionUpdate.setParams(objParams);
		actionUpdate.setCallback(this, function (response) {
			if (response.getState() == "SUCCESS") {
				console.debug('BAM_assetCreation::updateApplications');
				var objResponse = response.getReturnValue();

				// refresh the account-product statuses, same as init load
				var arrProducts = objResponse.products;
				helper.refreshProductsList(component, arrProducts);

				component.set('v.showSpinner', false);
			}
		});
		$A.enqueueAction(actionUpdate);
	}


	, onChangeSearchContact : function (component, event, helper)
	{
		helper.filterContacts(component);
	}

	, onSelectContact: function (component, event, helper) {
		// set the selected contact Id
		component.set('v.contactId', event.getSource().get('v.value'));
		component.set('v.enableProvisionContact', true);
	}

	, onClickProvisionContact:function (component, event, helper)
	{
		var contactId = event.getSource().get("v.name");
		var myEvent = $A.get("e.c:AsynchApexContinuationRequest");

		var evtParams = {
			className: 'BAM_onboarding',
			methodName: 'Open new window',
			methodParams:'/apex/BAMOnboardContact?contactId=' + contactId,
			callback:'',
			useAsynchCallout:true
		};
		myEvent.setParams(evtParams);
		myEvent.fire();
	}

	, onClickProvision:function(component, event, helper)
	{
		var contactId = component.get('v.contactId');
		var urlEvent = $A.get("e.force:navigateToURL");
		urlEvent.setParams({
			"url": '/apex/BAM_onboardingVF?contactId=' + contactId
		});
		urlEvent.fire();


		var myEvent = $A.get("e.c:AsynchApexContinuationRequest");

		var evtParams = {
			className: 'BAM_onboarding',
			methodName: 'send to Camunda',
			methodParams:'/apex/BAMOnboardContact?contactId=' + contactId,
			callback:'',
			useAsynchCallout:true
		};
		myEvent.setParams(evtParams);
		myEvent.fire();
	}

	, redirectToContact: function (component, event, helper) {
		//let contactId = event.getSource().get("v.name");
		let contactId = event.currentTarget.dataset.id;
		let myEvent = $A.get("e.c:AsynchApexContinuationRequest");

		let evtParams = {
			className: 'BAM_onboarding',
			methodName: 'Open new window',
			methodParams:'/' + contactId,
			callback:'',
			useAsynchCallout:true
		};
		myEvent.setParams(evtParams);
		myEvent.fire();
    }
})