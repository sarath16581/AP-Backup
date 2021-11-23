/**
 * @description This is the interface controller. This has been disconnected from the main CTI adapter framework flows as much as possible to maintain a suitable level of separation.
				This is the interface to handle any interaction from service cloud such as navigation and also to handle displaying information received when an interaction starts
 * @author Nathan Franklin
 * @date 2018-08-22
 * @changelog
 * 2021-09-07 - Nathan Franklin - Fixed long time bug where business contacts where not being correctly set on the Task record
 */
define(['jquery', 'config', 'AP/utils', 'AP/integration', 'SFDC/tracking'],
	function ($, config, apUtils, apIntegration, tracking) {
		var log_prefix = 'controller/controller: ';

		var model = new localState();

		var initialize = function() {
		    wireEvents();
			updateDisplay();
		};

		var wireEvents = function() {
			// catch events fired from the CTI framework to display the current contact/case context
		  	sforce.console.addEventListener('CTILoaded_Contact', contactLoaded);
		  	sforce.console.addEventListener('CTILoaded_Case', caseLoaded);
		  	sforce.console.addEventListener('CTILoaded_PhoneNumber', phoneNumberLoaded);

		  	// After CaseDetails.page is refreshed an event is fired which we catch to force attached Case details to be updated in the current interaction (if there is an active interaction)
		  	sforce.console.addEventListener('CaseDetails_Refreshed', caseDetailsRefresh);

		  	// this will extract the case data out of the userData node sent from Workspace.
		  	// we use this populate the interface
		  	sforce.console.addEventListener('CTILoaded_CaseMappings', caseMappingsLoaded);

		  	// fired whenever a new voice interaction is received in AP/connected.js
		  	sforce.console.addEventListener('CTILoaded_VoiceInteractionId', setVoiceInteractionId);

		  	// At the end of every interaction, a voice.ended event is caught in AP/connected.js and broadcasts a CTILoaded_ClearValues event
           	// This is used to clear all the display values received from the call
		  	sforce.console.addEventListener('CTILoaded_ClearValues', clearValues);

			// when the user navigates from case to case or contact to contact
			// we continually update current 'record' in Workspace
			// in normal circumstances, the agent should only ever be looking at a contact and case for the current customer they are talking to.
		  	sforce.console.onFocusedSubtab(onFocusedSubTab);
		  	sforce.console.onFocusedPrimaryTab(onFocusedPrimaryTab);
		  	sforce.console.onEnclosingTabRefresh(onEnclosingTabRefresh);
  		};

		/**
		 * Clear all display values that have been stored from the result of a voice interaction
		 */
  		var clearValues = function() {
  		    console.log(log_prefix, 'CTILoaded_ClearValues');

  			model.set('ivrCase', {});
			model.set('contactId', '');
			model.set('contactName', '');
			model.set('caseId', '');
			model.set('caseNumber', '');
			model.set('phoneNumber', '');
			model.set('voiceInteractionId', '');
            model.set('serviceCloudCase', '');
            model.set('serviceCloudContact', '');
            model.set('serviceCloudCaseContact', '');
            model.set('lastLoadedId', '');

			updateDisplay();
    	};

		// this is called when the CTI adapter matches the incoming call to a contact
		// this could happen in addition to a case match being fired too
		var contactLoaded = function(result) {
		    console.log(log_prefix, 'CTILoaded_Contact', result);
		    var obj = JSON.parse(result.message);
			model.set('contactId', obj.contactId);
			model.set('contactName', obj.name);
			updateDisplay();
    	};

  		// this is called when the cti adapter matches the incoming call to a case
  		// this could happen in addition to a contact match being fired too
  		var caseLoaded = function(result) {
  		    console.log(log_prefix, 'CTILoaded_Case', result);
			var obj = JSON.parse(result.message);
			model.set('caseId', obj.caseId);
			model.set('caseNumber', obj.caseNumber);
			updateDisplay();
    	};

		// this is called when the cti adapter receives a phone number
    	var phoneNumberLoaded = function(result) {
    	    console.log(log_prefix, 'CTILoaded_PhoneNumber', result);
			var obj = JSON.parse(result.message);
			model.set('phoneNumber', obj.phoneNumber);
			updateDisplay();
		};

		var setVoiceInteractionId = function(result) {
		    console.log(log_prefix, 'CTILoaded_VoiceInteractionId', result);
			var obj = JSON.parse(result.message);
			model.set('voiceInteractionId', obj.voiceInteractionId);
  		};

		/**
		 * When a voice call is received, parameters are extracted out of the call values and pass here through the CTILoaded_CaseMappings event
		 * The interface is responsible just for display the current state of the IVR
		 */
  		var caseMappingsLoaded = function(result) {
  		    console.log(log_prefix, 'CTILoaded_CaseMappings', result);
  		    var mappings = JSON.parse(result.message);

			// example { Id: '', Type: '', ProductCategory__c: '', ... }
			model.set('ivrCase', mappings);

			updateDisplay();
    	};

		// monitor tab activations to send back to the CTI adapter to ensure the correct contact/person account/case is matched to the current call
		var onFocusedSubTab = function(result) {
		    if(interactionIsCurrent()) {
		    	console.log(log_prefix, 'onFocusedSubTab', result);
				processFocusedTab(result, false);
			}
		};

		// monitor tab activations to send back to the CTI adapter to ensure the correct contact/person account/case is matched to the current call
		var onFocusedPrimaryTab = function(result) {
		    if(interactionIsCurrent()) {
		    	console.log(log_prefix, 'onFocusedPrimaryTab', result);
				processFocusedTab(result, false);

                // TODO... Also process subtab if the object id is different from the primary tab
				// Need to implement this functionality
			}
		};

		var onEnclosingTabRefresh = function(result) {
		    if(interactionIsCurrent()) {
		    	console.log(log_prefix, 'onEnclosingTabRefresh', result);
				processFocusedTab(result, false);
			}
		};

		// when the CaseDetails page is refreshed, we push new details into the current interaction
		var caseDetailsRefresh = function(result) {
			if(interactionIsCurrent()) {
				console.log(log_prefix, 'CaseDetails_Refreshed', result);
				processFocusedTab({objectId: result.message}, true);
   			}
  		};

		/**
		 * Whenever a tab event occurs within service cloud console we need to reattach the details to the interaction to ensure all the latest/correct details are attached
		 * This is called when primary tab is focused, sub tab is focused, an enclosing tab is refreshed and also when case details are updated
		 */
		var processFocusedTab = function(result, forceUpdate) {
			var objectId = result.objectId;
			if(!apUtils.isEmpty(objectId)) {
				console.log(log_prefix, 'Handling focus for', objectId);

			    // this is to stop duplicates from a primary and subtab event with the same object being fired together
			    // sometimes we may need to force the reattachment of data to the interaction (CaseDetails_Refresh is one example of this where the event is fired when the tab is focused, but then we need to reattach new details after the case is saved)
			    if(model.get('lastLoadedId') === objectId && !forceUpdate)
			    	return;

				// make sure this id isn't processed twice in a row
			    model.set('lastLoadedId', objectId);

			    var objectPrefix = objectId.substr(0, 3);
			    var objectId15 = objectId.substr(0, 15);

			    // we are only concerned with case, person account and contact
				if(objectPrefix === '003') { // contact
					model.set('serviceCloudContact', objectId15);

					// send updated data to workspace
					// 2021-09-06 - changed setCTIContactData(false) to the below... I'm not sure why this was ever 'false'??
					setCTIContactData(objectId15);
    			} else if(objectPrefix === '500') { // case

    				// remote call to get the details about the case
    				// NOTE: If a contact is attached to a case, this will also link the contact to the current interaction (BUT only if one wasn't found at the start of the interaction)
    				apIntegration.getCaseById(objectId, function(result) {
    				    result.Id = result.Id.substr(0, 15);

						model.set('serviceCloudCase', result);
                        model.set('serviceCloudCaseContact', null);

						// if a contact is linked to the case, then this becomes the active contact
						// check for the existence of a person account first
						if(!apUtils.isEmpty(result.Account) && !apUtils.isEmpty(result.Account) && !apUtils.isEmpty(result.Account.IsPersonAccount) && result.Account.IsPersonAccount === true) {
							var contact15 = result.AccountId.substr(0, 15);
							model.set('serviceCloudCaseContact', contact15);
                            setCTIContactData(contact15);
						} else if(!apUtils.isEmpty(result.ContactId)) {
						    var contact15 = result.ContactId.substr(0, 15);
							model.set('serviceCloudCaseContact', contact15);
						    setCTIContactData(contact15);
      					}

						// send updated data to workspace
      					setCTICaseData();
        			});
    			} else if(objectPrefix === '001') { // account
    				// check for person account
					// because this is an account record, the only accounts we are interested in are person accounts
					// all other contacts will be a 'Contact' record.
					isPersonAccount(objectId, function(result) {
					    if(result) {
					    	model.set('serviceCloudContact', objectId15);

							// send updated data to workspace
					    	setCTIContactData(objectId15);
					    }
					});
    			}

   			}
  		};

  		/**
  		 * This will push data to Workspace if the transaction id is still being tracked
  		 * NOTE: This is also used to push the case details that are initially loaded with the CTI Adapter's pop functionality
  		 *			This happens by default given that we are monitoring for tab changes
  		 *
  		 * NOTE: We only do this if we weren't able to determine a single Case at the start of the interaction OR if the Case (serviceCloudCase) is the case that was matched at the start of the interaction
  		 */
  		var setCTICaseData = function() {
  		    console.log(log_prefix, 'setCTICaseData');

			var voiceInteractionId = model.get('voiceInteractionId');
			var currentCase = model.get('serviceCloudCase'); // will always exist from call to apIntegration.getCaseById
			var currentCaseId = currentCase.Id.substr(0, 15);
			var userId = config.USER_ID;

			// is the interaction being tracked in the CTI framework
			var trackingExists = tracking.exists(voiceInteractionId);

			// was a case matched at the start of the interaction with the supplied payload
			var trackingCaseId = tracking.getCaseId(voiceInteractionId);

			// grab the 15 character id
			if(!apUtils.isEmpty(trackingCaseId))
				trackingCaseId = tracking.getCaseId(voiceInteractionId).substr(0, 15);

			// does the current case being viewed in service cloud match the case being tracked for the current interaction
			var isTrackingCaseMatch = (trackingExists && !apUtils.isEmpty(trackingCaseId) && trackingCaseId === currentCaseId);

			// make sure we only attach data thats relevent to the interaction.
			// 1. make sure the voiceInteractionId stored in the model is still being tracked in the framework
			// 2. Make sure the current case opened in Service Cloud is the same case linked to the interaction (found at the start of the interaction based on the payload)
			//  	OR 3. There was no case match at the start of the interaction (based on the payload from genesys)
			if((trackingExists && isTrackingCaseMatch)
					|| (trackingExists && apUtils.isEmpty(trackingCaseId))) {

				var actionData = apUtils.getCaseAttachmentActionData(voiceInteractionId, currentCase);

				// update the CTI Framework tracking node with the service cloud case details
				// these details are used at the end of the interaction to update the final call log task record
				setCustomTrackingParams(voiceInteractionId, { caseId: currentCaseId });

				// push the data to Workspace (this is picked up in the CTI Adapter connected.js native code)
				console.log(log_prefix, 'Attaching Case Details to Genesys: ', actionData);
				apIntegration.sendAttachmentData(actionData);

			}
  		};

  		/**
		 * This will push contact data to Workspace if the transaction id is still being tracked
		 * NOTE: This is also used to push the contact id that's initially loaded with the CTI Adapter's pop functionality
		 *			This happens by default given that we are monitoring for tab changes
		 */
  		var setCTIContactData = function(currentContact) {
  		    console.log(log_prefix, 'setCTIContactData');

			var voiceInteractionId = model.get('voiceInteractionId');
            var currentCase = model.get('serviceCloudCase');
			var userId = config.USER_ID;

			// is the interaction being tracked in the CTI framework
			var trackingExists = tracking.exists(voiceInteractionId);
			if(!trackingExists)
				return;

			// make sure that if a case has been tagged then only allow attaching the contact from the case
			// note that is a case changes then this should attach the new contact from the case
            var currentContactIsCaseContact = (currentContact === model.get('serviceCloudCaseContact'));
            var caseHasContact = !apUtils.isEmpty(model.get('serviceCloudCaseContact'));
            var hasCurrentServiceCloudCase = !apUtils.isEmpty(currentCase);

			// was a contact matched at the start of the interaction with the supplied payload
			var trackingContactExists = !apUtils.isEmpty(tracking.getContact(voiceInteractionId));

			// Contacts for ALL outbound calls must be matched through the initial params passed into SF from Workspace
			// if the call is an outbound call then we only send contact details to Workspace if a contact was matched at the start of the interaction.
			// this excludes Callback calls
			var isOutboundCall = (tracking.getCallType(voiceInteractionId) === 'Outbound' && tracking.getCallbackStatus(voiceInteractionId) !== 'Success');

			// does the current contact being viewed in service cloud match the contact being tracked for the current interaction
			var trackingContactId = (trackingContactExists && !apUtils.isEmpty(tracking.getContact(voiceInteractionId).Id) ? tracking.getContact(voiceInteractionId).Id.substr(0, 15) : '');
			var trackingAccountId = (trackingContactExists && !apUtils.isEmpty(tracking.getContact(voiceInteractionId).AccountId) ? tracking.getContact(voiceInteractionId).AccountId.substr(0, 15) : '');
			var isTrackingContactMatch = (trackingContactExists && (trackingContactId === currentContact || trackingAccountId === currentContact));

			console.log(log_prefix, currentContactIsCaseContact, caseHasContact, hasCurrentServiceCloudCase, trackingExists, trackingContactExists, isTrackingContactMatch, trackingContactId, trackingAccountId, currentContact, tracking.getContact(voiceInteractionId), isOutboundCall);

			// make sure we only attach data thats relevent to the interaction.
			// 1. Make sure the current contact opened in Service Cloud is the same contact linked to the interaction (found at the start of the interaction based on the payload)
            //          ^^ This will include the contact found from any case that is found at the start of the interaction
			// 2. If not contact linked at start of interaction AND If a case has been viewed in servicecloud and the current contact is the same as the contact from the case
            // 3. If not contact linked at start of interaction AND not case has been viewed OR case has been viewed and it has no contact
			// NOTE ON OUTBOUND CALLS - outbound calls must be matched to a contact at the start of the interaction
            if((trackingContactExists && isTrackingContactMatch)
                    || (!trackingContactExists && !isOutboundCall && hasCurrentServiceCloudCase && caseHasContact && currentContactIsCaseContact)
                    || (!trackingContactExists && !isOutboundCall && (!hasCurrentServiceCloudCase || (hasCurrentServiceCloudCase && !caseHasContact)))) {


				var actionData = {};
				actionData.id = voiceInteractionId;
				actionData.SF_UserId = userId;
				actionData.sfdcObjectId = currentContact;
                actionData.ContactId = currentContact;

				// update the CTI Framework tracking node with the service cloud case details
				// these details are used at the end of the interaction to update the final call log task record
				setCustomTrackingParams(voiceInteractionId, { contactId: currentContact });

				// push the data to Workspace (this is picked up in the CTI Adapter connected.js native code)
				console.log(log_prefix, 'Attaching Contact Details to Genesys: ', actionData);
				apIntegration.sendAttachmentData(actionData);

			}
		};

		/**
		 * When the user navigates around service cloud (clicking on contacts, cases) we need a way to pass this back into the CTI framework
		 *
		 * This method will set a tempCaseId and tempContactId to be used when the CTI Adapter is not able to match a call to a contact or case immediately (using search/create functions in the normal CTI flow)
		 * These value are used in AP/task.js taskFinish method which is called after voice.ended message is fired
		 * These will be used if a task was not created in the initial CTI Flow (where a contact/case was searched/created)
		 */
		var setCustomTrackingParams = function(voiceInteractionId, pageVars) {
			if(tracking.exists(voiceInteractionId)) {
				var custom = tracking.getCustom(voiceInteractionId);
				if(apUtils.isEmpty(custom)) {
				    custom = {};
    			}

				if(!apUtils.isEmpty(pageVars.caseId)) {
					custom.tempCaseId = pageVars.caseId;
				}

				if(!apUtils.isEmpty(pageVars.contactId)) {
					custom.tempContactId = pageVars.contactId;
				}

				// update all the details
				tracking.setCustom(voiceInteractionId, custom);
			}
		};

		/**
		 * This will check the Salesforce if the currently open account is a person account or not
		 * We also cache the result to minimise requests to server
		 */
  		var isPersonAccount = function(id, completionCallback) {
  		    var cache = model.get('personAccountCache');
			if(apUtils.isEmpty(cache)) {
				cache = {};
   			}

   			if(cache.hasOwnProperty(id)) {
   			    completionCallback(cache[id]);
      		} else {
      		 	// remoteaction call
                apIntegration.isPersonAccount(id, function(result) {
                    // add this personaccount into the cache so future requests do not need to be made
            		var cache = model.get('personAccountCache') || {};
					cache[id] = result;
					model.set('personAccountCache', cache);

                	completionCallback(result);
                });
        	}
		};

		/**
		 * Render the display of the CTI adaptor
		 */
		var updateDisplay = function() {
		    console.log(log_prefix, model);

			var $txtPhoneNumber = $('#txtPhoneNumber');
			var $txtContact = $('#txtContact');
			var $txtCase = $('#txtCase');

			var caseId = model.get('caseId');
			var caseNumber = model.get('caseNumber');
			var contactId = model.get('contactId');
			var contactName = model.get('contactName');
			var phoneNumber = model.get('phoneNumber');

			var displays = [
			  	[$txtPhoneNumber, phoneNumber],
			  	[$txtContact, contactName],
			  	[$txtCase, caseNumber]
   			];

			// populate the values that were pass through from Workspace
   			var ivrCase = model.get('ivrCase'); // example { Type: '', ProductCategory__c: '', ... }
			if(apUtils.isEmpty(ivrCase))
				ivrCase = {};

			var caseKeys = Object.keys(config.CASE_MAPPINGS);
			for(var i=0;i<caseKeys.length;i++) {
			    var fieldValue = (ivrCase.hasOwnProperty(caseKeys[i]) ? ivrCase[caseKeys[i]] : '');
			    displays.push([$('input[id=' + caseKeys[i] + ']'), fieldValue]);
   			}

			for(var i=0;i<displays.length;i++) {
			 	if(!apUtils.isEmpty(displays[i][1])) {
					displays[i][0].val(displays[i][1]);
					displays[i][0].closest('tr').show();
				} else {
					displays[i][0].closest('tr').hide();
				}
   			}
  		};

		/**
		 * This will ensure that the controller interface only responds if the interaction id stored in the controller is the current interaction
		 * See CTILoaded_ClearValues event listener for more details
		 */
  		var interactionIsCurrent = function() {
  		    var voiceInteractionId = model.get('voiceInteractionId');
            return (!apUtils.isEmpty(voiceInteractionId) && tracking.exists(voiceInteractionId));
		};

		var constructor = function() {
		    this.model = model;
  		};
		constructor.prototype.initialize = initialize;
		return constructor;
	}
);