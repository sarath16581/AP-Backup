/**
 * 2020-05-27 - Nathan Franklin - Included the search billing account selector table and fixed some minor UI bugs
 * 2023-07-08 - Mahesh Parvathaneni - Updated the appState to include the billing accounts
 * 2024-02-16 - Jacob.Isaac@auspost.com.au - Added Consignment Searching option in Merchant Portal - REQ2982613
 */
({
	/**
	 * Main setup function
	 * @param component
	 * @param arrApplications
	 * @param contactApplications
	 * @param mapAppToRoles
	 */
	parseApplications : function(component, arrApplications, contactApplications, mapAppToRoles, billingAccountsByApp)
	{
		var pendingCount = 0;
		var pageState = [];
		var hasPending = false;

		// loop through to set the top-level status of the application based on requests
		for(var i = 0; i < arrApplications.length; ++i)
		{
			// page state variables are camel case starting with lower-case, sObject fields are capitalized
			var app = arrApplications[i];

			// format the Application-Roles into radio group options
			app.ApplicationRoleOptions = this.formatApplicationRoles(component, app.ApplicationRoles__r);

			// get the noaccess role option, which is the LAST one
			var noAccessRole = app.ApplicationRoleOptions[app.ApplicationRoleOptions.length - 1];

			// create a holder for the contact role, this will be used to compare on submit
			var stateRole = {
				ApplicationRole__c: noAccessRole.value,
				Application__c: app.Id,
				selectedEntities:[]
			};

			var contactRole = mapAppToRoles[app.Id];
			var contactApplication = contactApplications[app.Id];
			var requests = (contactApplication && contactApplication.BAM_External_Onboarding_Requests__r ? contactApplication.BAM_External_Onboarding_Requests__r : []);
			if(contactRole)
			{
				// current app status
				app.applicationStatus = contactApplication.Status__c;
				app.BSPCanViewAllConsignments__c = contactApplication.BSPCanViewAllConsignments__c;
				// store the existing, using the naming convention
				app.ContactRole__c = contactRole;
				// need to store the Application Id here for easier mapping when creating SF Records on save
				contactRole.Application__c = app.Id;

				// transfer the SF record fields to the page state
				stateRole.ApplicationRole__c = contactRole.ApplicationRole__c;
				// store the existing Record Id
				stateRole.Id = contactRole.Id;

				// format the linked entities so that the dual list box reflects it
				if(contactRole.LinkedEntities__r)
				{
					stateRole.selectedEntities = this.formatBillingAccounts(contactRole.LinkedEntities__r);
					// store them in the same format on the original state for easier comparing on save
					contactRole.LinkedEntities = stateRole.selectedEntities;
				}
				else
				{
					contactRole.LinkedEntities = [];
				}


				/*
				// if the current role is active, no editing here
				if(contactRole.Status__c == 'Active') {
					app.status = 'provisioned';
					app.showDelete = true;
					app.statusMessage = 'Edit this Application in BAM';
					app.locked = false;
				}

					*/

				// set any statuses by the latest request

				if(requests && requests.length == 1)
				{
					let lastRequest = requests[0];
					let status = lastRequest.Status__c.toLowerCase();
					switch(status)
					{
						case 'error':
							app.statusMessage = 'Error in your last request, error message: ' + lastRequest.Error__c;
							app.status = 'error';
							break;
						case'pending':
							pendingCount++;

							app.statusMessage = 'There is a provisioning/deprovisioning request pending, try again later';
							app.status = 'pending';
							app.showDelete = false;
							app.locked = true;
							app.requestDate = lastRequest.Request_Date__c;
							app.startedDate = lastRequest.StartedResponseReceived__c;
							app.requestType = lastRequest.Type__c;
							app.createdBy = '';
							app.createdByUserType = '';

							//console.log(lastRequest.CreatedBy);
							if(lastRequest.CreatedBy) {
								app.createdBy = lastRequest.CreatedBy.Name;
								app.createdByUserType = (!lastRequest.CreatedBy.UserType ? '' : (lastRequest.CreatedBy.UserType != 'Standard' ? 'External' : 'Internal'));
							}

							hasPending = true;
							break;
						case 'success':
							break;
					}
				}
			}
			else
			{
				// unlock it if there are no contact roles (or previously deleted)
				app.locked = false;
			}
			app.contactRole = stateRole;

			if (app.Name == 'Business Support Portal'){
				app.isBSP = true;
			}
			//get the billing accounts by app
			app.billingAccountOptions = [];
			let billingAccountWrapperData = billingAccountsByApp.find(billingAccountData => app.Id === billingAccountData.bamApplicationId);
			if(billingAccountWrapperData){
				app.billingAccounts = billingAccountWrapperData.billingAccounts;
				//set the billing account options for the dropdown
				app.billingAccountOptions = this.parseBillingAccounts(app.billingAccounts);
			}

			pageState.push(app);
		}
		component.set('v.applications', arrApplications);
		component.set('v.pageState', pageState);
		component.set('v.hasPending', hasPending);
		component.set('v.pendingCount', pendingCount);

	}


	/**
	* Helper function to store the roles as option objects which the RadioGroup can use
	* @param applicationRoles
	* @returns {Array}
	*/
	, formatApplicationRoles:function(component, applicationRoles__r)
	{
		var applicationRoles = component.get('v.applicationRoles');

		// create a pseudo app role for no access
		let firstRole = applicationRoles__r[0];
		let noAccessId = '_' + firstRole.Application__c;

		let roleNoAccess = {
			'Id':noAccessId,
			'Application__c':firstRole.Application__c,
			'ShowBillingAccounts__c':false
		};
		applicationRoles.push(roleNoAccess);
		applicationRoles = applicationRoles.concat(applicationRoles__r);
		component.set('v.applicationRoles', applicationRoles);

		var options = [];

		for(var i = 0; i < applicationRoles__r.length; ++i)
		{
			var role = applicationRoles__r[i];

			var opt = {
				'label': role.Role__c,
				'value':role.Id
			}
			options.push(opt);
		}


		// add the 'no access' option
		options.push({'label': 'No Access', 'value':noAccessId});

		return options;
	}

	, initBillingAccountsVisibility:function(component)
	{
		let pageState = component.get('v.pageState');

		for(let i = 0; i < pageState.length; ++i)
		{
			let app = pageState[i];
			let idRole = app.contactRole.ApplicationRole__c;
			if(idRole != '') {
				this.updateBillingAccountsVisibility(component, idRole);
			}
		}

	}

	, updateBillingAccountsVisibility:function(component, idRole)
	{
		// look for the Application Role to see if we need to show the billing accounts
		let appRole = this.findApplicationRoleById(component, idRole);
		var divBillingAccounts = document.getElementById(appRole.Application__c);
		if(divBillingAccounts) {
			if (appRole.ShowBillingAccount__c == true) {
				divBillingAccounts.style.display = 'block';
			} else {
				divBillingAccounts.style.display = 'none';
			}
		}
	}
	,updateBSPCanViewAllConsignments:function(component, viewAllConsignment)
	{
		try{
		//appState.BSPCanViewAllConsignments__c = viewAllConsignment;
		let pageState = component.get('v.pageState');
		//console.log('pageState in console on checking box');
		//console.log(JSON.stringify(pageState));
		for(let i = 0; i < pageState.length; ++i)
		{
			let app = pageState[i];
			
			if(app.isBSP==true){
				//console.log('app within for loop');
			//console.log(app.Name);
				app.BSPCanViewAllConsignments__c = viewAllConsignment;
			}
		}
		}
		catch(err){
			console.error(err);
		}
	}

	, findApplicationRoleById:function(component, idRole)
	{
		var applicationRoles = component.get('v.applicationRoles');
		for(var i = 0; i < applicationRoles.length; ++i) {
			var appRole = applicationRoles[i];
			if (appRole.Id == idRole)
				return appRole;
		}
	}

	/**
	* Helper function format the selection in a string array for preselection of dual listboxes
	* @param arrEntities
	* @returns {Array}
	*/
	, formatBillingAccounts:function(arrEntities)
	{
		if(!arrEntities)
			return [];

		var arrBillingAccountIds = [];
		for(var i = 0; i < arrEntities.length; ++i)
		{
			arrBillingAccountIds.push(arrEntities[i].BillingAccount__c);
		}
		return arrBillingAccountIds;
	}

	/**
	* Helper function to format static data of Billing Accounts
	* @param component
	* @param arrBillingAccounts
	*/
	, parseBillingAccounts: function(arrBillingAccounts)
	{
		let arrOptions = [];

		for(let i = 0; i < arrBillingAccounts.length; ++i)
		{
			let ba = arrBillingAccounts[i];
			let baName = ba.Name;

			let baIds = '';
			if(ba.MLID__c) {
				baIds += ba.MLID__c + ' ';
			}
			if(ba.LEGACY_ID__c) {
				baIds += ba.LEGACY_ID__c;
			}

			if(baIds != '')
				baName = baIds + ' ' + baName;

			let objOption = {
				'label':baName,
				'value':ba.Id
			}
			arrOptions.push(objOption);
		}

		return arrOptions;
	}

	// UI function to expand all accordion sections
	, openAllSections:function(component)
	{
		var arrApplications = component.get('v.applications');

		var arrOpen = [];
		for(var i = 0; i < arrApplications.length; ++i)
		{
			var app = arrApplications[i];
			arrOpen.push(app.Name);
		}
		component.set('v.openApplicationSections', arrOpen);
	}

	, submitCancellationRequest: function(component) {
		//console.debug('submitCancellationRequest');

		var contactId = component.get('v.contactId');

		component.set('v.showSpinner', true);

		// send to apex for DML
		var actionSave = component.get("c.submitContactCancellationRequest");
		var objParams = {
			'contactId': contactId
		};
		actionSave.setParams(objParams);
		actionSave.setCallback(this, function (response) {

			if (response.getState() == "SUCCESS") {
				var objResponse = response.getReturnValue();
				//console.debug(objResponse);

				// check for any user creation errors
				if(objResponse.status == 'Error') {
					alert(objResponse.message);
				} else {
					window.location.reload();
					return;
				}
			}
			else {
				var errors = response.getError();
				if (errors) {
					if (errors[0] && errors[0].message) {
						alert("Error message: " +
							errors[0].message);
					}
				} else {
					alert('Error saving changes, please try again');
				}
			}
			component.set('v.showSpinner', false);
		});
		$A.enqueueAction(actionSave);
	}

	, saveProvisionState:function(component)
	{
		////console.debug('saveProvisionState');
		var pageState = component.get('v.pageState');
		var anyChanges = false;
		let missingBillingAccounts = false;

		for(var i = 0; i < pageState.length; ++i) {
			var appState = pageState[i];

			//console.log(JSON.stringify(appState));

			// store the changes per app
			appState.destructive = [];
			appState.upsert = [];

			// the role which is currently selected on the page
			var pageRole = appState.contactRole;

			// the role which was retrieved from APEX
			var sfRole = appState.ContactRole__c;

			// compare to get the changes
			if(!sfRole)
			{
				// no existing access
				if(pageRole.ApplicationRole__c && pageRole.ApplicationRole__c[0] != '_')
				{
					appState.upsert.push(pageRole);
				}
			}
			else
			{
				// existing access, compare if anything has changed
				if(pageRole.ApplicationRole__c != sfRole.ApplicationRole__c)
				{
					// remove existing
					appState.destructive.push(sfRole);

					if(pageRole.ApplicationRole__c != null && pageRole.ApplicationRole__c[0] != '_')
					{
						// it could be just a remove, and not adding anything
						appState.upsert.push(pageRole);
					}
				}
				else
				{
					// check if any of the linked entities have changed
					var pageEntities = pageRole.selectedEntities;
					var sfEntities = sfRole.LinkedEntities;
					var diff = this.difference(pageEntities, sfEntities).concat(this.difference(sfEntities, pageEntities));

					// there has been a change of some sort
					if(diff.length != 0)
					{
						appState.upsert.push(pageRole);
					}
				}
			}

			// check if billing accounts need to be added
			let appRole = this.findApplicationRoleById(component, pageRole.ApplicationRole__c)
			{
				if(appRole && appRole.ShowBillingAccount__c == true
					&& (!pageRole.selectedEntities || pageRole.selectedEntities.length < 1))
				{
					//console.debug('missing billing accounts for ' + i);
					missingBillingAccounts = true;
				}
				else if (!appRole || appRole.ShowBillingAccount__c == false)
				{
					pageRole.selectedEntities = [];
				}
			}


			if(appState.upsert.length != 0 || appState.destructive.length != 0)
				anyChanges = true;
		}


		if(missingBillingAccounts)
		{
			alert('1 or more roles are missing a billing account');
			return;
		}

		// Set the updated Primary Billing Account to the Contact
		var contact = component.get('v.contactObj');
		var primaryBillingAccount = contact.BillingAccount__c;
		//console.debug('Set new primaryBillingAccount', primaryBillingAccount);

		// attempt to save regardless of UI changes, in case a Primary Billing Account has been added

		component.set('v.showSpinner', true);

		//console.debug('pageState to send');
		//console.debug(pageState);
		// console.log('full structure');
		// console.log(pageState);
		// console.log(JSON.stringify(pageState));
		var contactId = component.get('v.contactId');
		// send to apex for DML
		var actionSave = component.get("c.saveProvisionRequests");
		var objParams = {
			'contactId': contactId,
			'pageState': pageState,
			'primaryBillingAccount': primaryBillingAccount
		};
		actionSave.setParams(objParams);
		actionSave.setCallback(this, function (response) {

			if (response.getState() == "SUCCESS") {
				var objResponse = response.getReturnValue();
				//console.debug('OnboardContactComponent::after save');
				//console.debug(objResponse);

				// check for any user creation errors
				if(objResponse.status == 'Error')
				{
					alert('Error saving:' + objResponse.message );
				}
				else {
					window.location.reload();
					return;
				}


				/*
				var objContact = objResponse.contact;

				if (objContact) {
					// set the contact object
					component.set('v.contactObj', objContact);

					// parse the static + contact data again
					this.parseApplications(component,
						objResponse.applications,
						objResponse.requestsPerApplication,
						objResponse.contactRolesPerApplication);

					if(!alert(objResponse.message)) {
						//window.location.reload();
					}

					var objHelper = this;
					new Promise($A.getCallback(function (result) {
						setTimeout($A.getCallback(function () {
							objHelper.openAllSections(component);
						}), 100);
					}));

				} else {
					alert('Error occurred, please reload the page');
				}
				
					*/
			}
			else {
				var errors = response.getError();
				if (errors) {
					if (errors[0] && errors[0].message) {
						alert("Error message: " + 
									errors[0].message);
					}
				}
				else
				{
				alert('Error saving changes, please try again');
				}
			}
			component.set('v.showSpinner', false);
		});
		$A.enqueueAction(actionSave);
	}

	// , setSelectedBillingAccounts: function(component, applicationId, billingAccountIds) {
	// 	const pageState = component.get('v.pageState');
	// 	for(let i=0;i<pageState.length;i++) {
	// 		if(pageState.Id === applicationId) {
	// 			pageState[i].contactRole.selectedEntities = billingAccountIds;
	// 			break;
	// 		}
	// 	}
	//
	// 	// component.set('v.pageState', pageState);
	// 	// this.initBillingAccountsVisibility(component);
	// }

	, difference:function(a1, a2)
	{
		var a2Set = new Set(a2);
		return a1.filter(function(x) { return !a2Set.has(x); });
	}

	, getApplicationNameById:function(component, applicationId)
	{
		var arrApplications = component.get('v.applications');
		for(var i = 0 ; i < arrApplications.length; ++i)
		{
			var objApp = arrApplications[i];
			if(objApp.Id == applicationId)
				return objApp.Name;
		}
	}

	, saveDeprovision:function(component, applicationId)
	{
		component.set('v.showSpinner', true);
		var contactId = component.get('v.contactId');

		console.warn('about to remove access');
		var actionSave = component.get("c.deprovisionApplication");
		var objParams = {
			'contactId': contactId,
			'applicationId': applicationId
		};
		actionSave.setParams(objParams);
		actionSave.setCallback(this, function (response) {

			if (response.getState() == "SUCCESS") {
				var objResponse = response.getReturnValue();
				//console.debug('on save Deprovisioning request:');
				//console.debug(objResponse);
				window.location.reload();
				return;


				var objContact = objResponse.contact;

				if (objContact) {
					// set the contact object
					component.set('v.contactObj', objContact);

					// parse the static + contact data again
					this.parseApplications(component,
						objResponse.applications,
						objResponse.requestsPerApplication,
						objResponse.contactRolesPerApplication);

					var objHelper = this;
					new Promise($A.getCallback(function (result) {
						setTimeout($A.getCallback(function () {
							objHelper.openAllSections(component);
						}), 100);
					}));

				} else {
					alert('Error occurred, please reload the page');
				}
			}
			else {
				var errors = response.getError();
				if (errors) {
					if (errors[0] && errors[0].message) {
						alert("Error message: " + 
									errors[0].message);
					}
			}
			else
			{
			alert('Error saving changes, please try again');
			}
			}
			component.set('v.showSpinner', false);
		});
		$A.enqueueAction(actionSave);
	}
})