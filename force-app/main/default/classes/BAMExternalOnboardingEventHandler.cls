/***
 * @description
 * Utility class for managing the logic for BAM when a Platform event is received from Camunda
 * 
 * This class handles the following scenarios:
 * Provisioning >>>>
 * Started: The application provisioning flow commenced for a single application
 * Error: Either the Application Provsioning/Validation API's return an invalid response when invoked (or was not accessible) or the Application asynchronously returns a provisioning error
 * Expired: A successful call to the Application Provisioning API was made by Camunda, however the External Application did not return a response in the preconfigured timeout value
 * Fulfilled: The Application provisioning process was successfully completed for an individual application
 * 
 * Deprovisioning >>>>
 * Started: The application deprovisioning flow commenced for a single application
 * Error: Either the Application Deprovsioning API returns an invalid response when invoked (or was not accessible) or the Application asynchronously returns a deprovisioning error
 * Expired: A successful call to the Application Deprovisioning API was made by Camunda, however the External Application did not return a response in the preconfigured timeout value
 * Fulfilled: The Application deprovisioning process was successfully completed for an individual application
 * 
 * CSSO >>>>
 * Started: The contact passed in has entered into the CSSO flow.
 * Error: When the contact was entered into the CSSO flow, there was an error starting the process. (Could not retrieve token)
 * Expired: The user that was invited did not respond to the invite email email
 * NOTE: Camunda does not send a CSSO Fulfilled since this is managed by Salesforce when OneReg flow redirects back to Salesforce. Salesforce will invoke Camunda to inform Camunda that the registration process was successful.
 * 
 * This class is responsible for updating the External Onboarding Event table with the information that was received. The BAM UI utilises this information
 * 
 * @author Nathan Franklin
 * @date 2019-05-30
 * @group Merchant Portal
 * @changelog
 * 2019-08-12  nathan.franklin@auspost.com.au Updated to include record type checking
 * 2020-05-25 - Nathan Franklin - Added changes to support sorting of event messages and CSSO onboard dates
 */
public with sharing class BAMExternalOnboardingEventHandler {

	public static final Map<String, Integer> ONBOARDING_REQUEST_SORT_ORDER = new Map<String, Integer>{
			'Started' => 1,
			'Expired' => 2,
			'Error' => 3,
			'Fulfilled' => 4
	};

	public static final Map<String, List<String>> CAMUNDA_TYPES_STATUSES = new Map<String, List<String>>{
			'provision' => new List<String>{'started', 'error', 'expired', 'fulfilled'},
			'deprovision' => new List<String>{'started', 'error', 'expired', 'fulfilled'},
			'csso' => new List<String>{'started', 'error', 'expired', 'fulfilled'}
	};

	public static final String TYPE_PROVISION = 'Provision';
	public static final String TYPE_DEPROVISION = 'Deprovision';
	public static final String TYPE_CSSO = 'CSSO';
	public static final String STATUS_STARTED = 'Started';
	public static final String STATUS_FULFILLED = 'Fulfilled';
	public static final String STATUS_SUCCESS = 'Success';
	public static final String STATUS_ERROR = 'Error';
	public static final String STATUS_INACTIVE = 'Inactive';
	public static final String STATUS_EXPIRED = 'Expired';
	public static final String STATUS_PENDING = 'Pending';
	public static final String STATUS_ACTIVE = 'Active';

	/**
     * Process event messages to update the external onboarding state
     */
	public static void processBAMResponses(List<ExternalOnboardingEvent__e> listEvents) {
		processBAMResponses(listEvents, false);
	}

	/**
	 * Process event messages to update the external onboarding state
	 */
	public static void processBAMResponses(List<ExternalOnboardingEvent__e> listEvents, Boolean throwException) {
		// since we have multiple DML statements we use this to roll back if errors occur
		SavePoint sp = Database.setSavepoint();

		try {
			List<EventWrapper> wrappers = new List<EventWrapper>();
			Map<Id, SObject> updatable = new Map<Id, SObject>();
			Map<Id, BAMExternalOnboardingRequest__c> updatableEOR = new Map<Id, BAMExternalOnboardingRequest__c>();
			Map<Id, SObject> deletable = new Map<Id, SObject>();

			Set<String> contactIds = new Set<String>();
			Set<String> requestIds = new Set<String>();
			List<ExternalOnboardingEvent__e> processableApplication = new List<ExternalOnboardingEvent__e>();
			List<ExternalOnboardingEvent__e> processableCSSO = new List<ExternalOnboardingEvent__e>();

			// we need to sort the events by their status just incase they come through in an incorrect order
			// this has happened in the past
			for(ExternalOnboardingEvent__e listEvent : listEvents) {
				wrappers.add(new EventWrapper(listEvent));
			}
			wrappers.sort();

			// loop through all the platform events received in bulk and only process the events specific to BAM
			for(EventWrapper wrapperEvent : wrappers) {
				ExternalOnboardingEvent__e listEvent = wrapperEvent.event;

				String status = (String.isEmpty(listEvent.Status__c) ? '' : listEvent.Status__c.toLowerCase());
				String type = (String.isEmpty(listEvent.Type__c) ? '' : listEvent.Type__c.toLowerCase());
				if(listEvent.IsBam__c && CAMUNDA_TYPES_STATUSES.containsKey(type) && CAMUNDA_TYPES_STATUSES.get(type).contains(status)) {

					// make sure the request records already exist before we update them
					if(!String.isEmpty(listEvent.RequestNumber__c) && (TYPE_PROVISION.equalsIgnoreCase(listEvent.Type__c) || TYPE_DEPROVISION.equalsIgnoreCase(listEvent.Type__c))) {
						requestIds.add(listEvent.RequestNumber__c);
						processableApplication.add(listEvent);
					} else if(!String.isEmpty(listEvent.Contact__c) && TYPE_CSSO.equalsIgnoreCase(listEvent.Type__c)) {
						contactIds.add(listEvent.Contact__c);
						processableCSSO.add(listEvent);
					}
				}
			}

			if(!processableApplication.isEmpty() || !processableCSSO.isEmpty()) {

				// grab a list of the onboarding requests to be processed
				// we also filter these to make sure we are only processing the latest request
				// NOTE: There might be multiple event messages to be processed for a single request
				// this filtering only ensure we aren't processing stale requests
				Map<Id, BAMExternalOnboardingRequest__c> onboardingRequests = new Map<Id, BAMExternalOnboardingRequest__c>();
				if(!processableApplication.isEmpty()) {
					onboardingRequests = new Map<Id, BAMExternalOnboardingRequest__c>([
							Select Id, Status__c, Contact_Application__c, Contact_Application__r.Application__c, Contact_Application__r.Application__r.AppKey__c,
									Contact_Application__r.Pending_Delete__c, Contact_Application__r.Pending_Deactivation__c, Contact_Application__r.Status__c, Contact__c
							From BAMExternalOnboardingRequest__c
							Where Id In :requestIds
							And RecordTypeId = :BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID
					]);

					System.debug('>> onboarding requests before filtering: ' + onboardingRequests);

					// remove any responses received that are not from the LATEST request to minimise unintended results
					//      ... such as activating, deactiving or something that shouldn't be.
					onboardingRequests = filterOnboardingRequests(onboardingRequests);

					System.debug('>> onboarding requests after filtering: ' + onboardingRequests);

					// grab the contacts associated to the requests
					// this will be used to populate the BAMInviteAcceptedDate__c/BAMInviteRequestDate__c if required
					for(BAMExternalOnboardingRequest__c request : onboardingRequests.values()) {
						if(request.Contact__c != null) {
							contactIds.add(request.Contact__c);
						}
					}
				}

				// grab the contacts based on the ids in the CSSO responses
				Map<Id, Contact> eventContacts = new Map<Id, Contact>([Select Id, OID_ID__c, BAMInviteAcceptedDate__c, BAMInviteRequestDate__c From Contact Where Id In :contactIds]);

				// process all the provisioning responses that were received
				if (!processableApplication.isEmpty()) {
					processApplicationEvents(processableApplication, onboardingRequests, eventContacts, updatableEOR, updatable, deletable);
				}

				// process all the CSSO responses that were received
				if (!processableCSSO.isEmpty()) {
					processCSSOEvents(processableCSSO, eventContacts, updatableEOR, updatable);
				}

				System.debug('updatable: ' + updatable);
				System.debug('updatableEOR: ' + updatableEOR);
				System.debug('deletable: ' + deletable);

				// proceed to finalise updates and deletes in a Unit of Work fashion
				//List<String> orderPriority = new List<String>{'Contact', 'BAMContactApplication__c', 'BAMControlRole__c', 'BAMLinkedEntity__c', 'BAMExternalOnboardingRequest__c'};
				List<String> orderPriority = new List<String>{
						'Contact', 'BAMContactApplication__c', 'BAMControlRole__c', 'BAMLinkedEntity__c'
				};
				if (!updatable.isEmpty()) {
					update reorderUnitsOfWork(updatable, orderPriority).values();
				}

				// these records must be updated after the BAM auth records have been updated
				// this is to make sure the response date is set correctly
				if (!updatableEOR.isEmpty()) {
					// loop through all EOR record and set response date which should be after all APEX processing is complete
					for (BAMExternalOnboardingRequest__c record : updatableEOR.values()) {
						record.Response_Date__c = DateTime.now();
					}

					update updatableEOR.values();
				}

				if (!deletable.isEmpty()) {
					delete reorderUnitsOfWork(deletable, orderPriority).values();
				}
			}
		} catch(Exception exp) {
			// because we are doing multiple DML statements, we want all the DML's to be rolled back
			Database.rollback(sp);

			if(throwException) {
				throw exp;
			} else {
				// Error Logged to Exception object for analysis
				UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'BAM',
						BAMExternalOnboardingEventHandler.class.getName(), 'processBAMResponses',
						'ExternalOnboardingEventTrigger', LoggingLevel.ERROR);
			}
		}
	}

	/**
	 * Process all of the Application specific events.
	 * These are the events that have an associated Onboarding Request Id.
	 */
	private static void processApplicationEvents(List<ExternalOnboardingEvent__e> processableApplication, Map<Id, BAMExternalOnboardingRequest__c> onboardingRequests, Map<Id, Contact> requestContacts,
			Map<Id, SObject> updatableEOR, Map<Id, SObject> updatable, Map<Id, SObject> deletable) {

		List<BAMExternalOnboardingRequest__c> appRequestsProvFulfilled = new List<BAMExternalOnboardingRequest__c>();
		List<BAMExternalOnboardingRequest__c> appRequestsDeprovFulfilled = new List<BAMExternalOnboardingRequest__c>();
		Map<Id, BAMExternalOnboardingRequest__c> appRequestsDeprovErrored = new Map<Id, BAMExternalOnboardingRequest__c>();

		// loop through all the Application events that have been received
		// we need to validate the Application value (which is the App Key) as an additional verification check to ensure the right request id is supplied
		//      this is a failsafe which should not occur.
		for (ExternalOnboardingEvent__e listEvent : processableApplication) {

			Id requestId = null;
			try {
				requestId = Id.valueOf(listEvent.RequestNumber__c);
			} catch (Exception ex) { /* do nothing */
			}

			if (requestId != null) {
				BAMExternalOnboardingRequest__c request = onboardingRequests.get(requestId);

				System.debug(request);
				System.debug(listEvent);

				// only proceed if a matching EOR record is found
				// this is a verification of w[sohether the AppKey in the platform event matches the App Key in the EOR record that was created at the start of the process
				// also whether the current request is still in pending or whether it's been actioned already
				if (request != null && request.Contact_Application__r != null && request.Contact_Application__r.Application__r != null
						&& listEvent.Application__c.equalsIgnoreCase(request.Contact_Application__r.Application__r.AppKey__c)
						&& 'Pending'.equalsIgnoreCase(request.Status__c)) {
					// the request id and the appkey have been matched to an existing EOR record

					System.debug('>> Processing Event');

					Contact contact = requestContacts.get(request.Contact__c);

					// queue to EOR record to be updated with the response
					// see if we have already processed this request in a previous event message
					BAMExternalOnboardingRequest__c eorUpdate = (BAMExternalOnboardingRequest__c)updatableEOR.get(request.Id);
					if (eorUpdate == null) {
						eorUpdate = new BAMExternalOnboardingRequest__c(Id = request.Id, Response_Payload__c = JSON.serialize(listEvent));
					}
					if (STATUS_ERROR.equalsIgnoreCase(listEvent.Status__c)) {
						eorUpdate.ErrorResponseReceived__c = listEvent.CreatedDate;
					} else if (STATUS_STARTED.equalsIgnoreCase(listEvent.Status__c)) {
						eorUpdate.StartedResponseReceived__c = listEvent.CreatedDate;
					} else if (STATUS_FULFILLED.equalsIgnoreCase(listEvent.Status__c)) {
						eorUpdate.SuccessResponseReceived__c = listEvent.CreatedDate;
					}

					if (!String.isEmpty(listEvent.RequestNumber__c) && TYPE_PROVISION.equalsIgnoreCase(listEvent.Type__c)) {
						System.debug('>> Is Provision');

						// handle the response when it's related to Provisioning

						if (STATUS_ERROR.equalsIgnoreCase(listEvent.Status__c) || STATUS_EXPIRED.equalsIgnoreCase(listEvent.Status__c)) {
							System.debug('>> Is Provision Error');

							// Camunda encountered a provisoning error
							// NOTE: No additional records need to be updated in this scenario apart from the EOR record
							//          All other records should remain in PENDING/PENDING DELETE state indefinitely until the user makes additional changes

							// set the error message recevied from the platform event if one was passed
							eorUpdate.Error__c = (String.isEmpty(listEvent.ResponseText__c) ? (STATUS_EXPIRED.equalsIgnoreCase(listEvent.Status__c) ? 'The provisioning process timed out' : 'Error occurred in the provisioning flow') : truncateTo(listEvent.ResponseText__c, 255));
							eorUpdate.Status__c = STATUS_ERROR;
							eorUpdate.ExpiredResponse__c = (STATUS_EXPIRED.equalsIgnoreCase(listEvent.Status__c) ? true : false);

							//
							//appRequestsProvErrored.add(request);

						} else if (STATUS_FULFILLED.equalsIgnoreCase(listEvent.Status__c)) {
							// Camunda completed the provisioning for a single application

							// remove any lingering error messages incase one was present
							eorUpdate.Error__c = '';
							eorUpdate.Status__c = STATUS_SUCCESS;

							// queue the application tidyup for a successful provision
							appRequestsProvFulfilled.add(request);

							// if the contact record's BAMInviteAcceptedDate__c and BAMInviteRequestDate__c fields do not have a value, then we set them to be the current
							// these fields normally get populated when the user is invited to CSSO (via merchant portal). If the user already has CSSO when they are first invited to merchant portal then these fields would never be set
							// we set them here in that case since this would be the first successful provisioning request
							if(contact.BAMInviteAcceptedDate__c == null || contact.BAMInviteRequestDate__c == null) {
								Contact contactUpdate = (Contact)updatable.get(contact.Id);
								if(contactUpdate == null) {
									contactUpdate = new Contact(Id = contact.Id);
								}
								if(contact.BAMInviteAcceptedDate__c == null) {
									contactUpdate.BAMInviteAcceptedDate__c = listEvent.CreatedDate;
								}
								if(contact.BAMInviteRequestDate__c == null) {
									contactUpdate.BAMInviteRequestDate__c = listEvent.CreatedDate;
								}
								updatable.put(contactUpdate.Id, contactUpdate);
							}
						}

					} else if (!String.isEmpty(listEvent.RequestNumber__c) && TYPE_DEPROVISION.equalsIgnoreCase(listEvent.Type__c)) {
						// handle the response when it's related to Deprovisioning

						if (STATUS_ERROR.equalsIgnoreCase(listEvent.Status__c) || STATUS_EXPIRED.equalsIgnoreCase(listEvent.Status__c)) {
							// Camunda encountered a deprovisioning error

							// set the error message recevied from the platform event if one was passed
							eorUpdate.Error__c = (String.isEmpty(listEvent.ResponseText__c) ? (STATUS_EXPIRED.equalsIgnoreCase(listEvent.Status__c) ? 'The deprovisioning process timed out' : 'Error occurred in the deprovisioning flow') : truncateTo(listEvent.ResponseText__c, 255));
							eorUpdate.Status__c = STATUS_ERROR;
							eorUpdate.ExpiredResponse__c = (STATUS_EXPIRED.equalsIgnoreCase(listEvent.Status__c) ? true : false);

							appRequestsDeprovErrored.put(request.Id, request);

						} else if (STATUS_FULFILLED.equalsIgnoreCase(listEvent.Status__c)) {
							// Camunda completed the deprovisioning for a single application

							// remove any lingering error messages incase one was present
							eorUpdate.Error__c = '';
							eorUpdate.Status__c = STATUS_SUCCESS;

							// queue the application tidyup for a successful deprovision
							appRequestsDeprovFulfilled.add(request);

							// make sure no deprovisioning errors have been previously queued up for prcessing
							if (appRequestsDeprovErrored.get(request.Id) != null) {
								// remove this from the list of deprovision failures to be processed since we have subsequently received a deprovision fulfilled request
								appRequestsDeprovErrored.remove(request.Id);
							}

						}
					}

					updatableEOR.put(eorUpdate.Id, eorUpdate);
				}
			}
		}

		// transition status from Pending to Active
		if (!appRequestsProvFulfilled.isEmpty()) {
			tidyupFulfilledProvResponses(appRequestsProvFulfilled, updatable, deletable);
		}

		// remove/deactivate the old records after a deprovision was successfully processed
		if (!appRequestsDeprovFulfilled.isEmpty()) {
			tidyupFulfilledDeprovResponses(appRequestsDeprovFulfilled, updatable, deletable);
		}

		// reset the state of the Contact Application records when a deprovision fails
		if (!appRequestsDeprovErrored.isEmpty()) {
			tidyupErroredDeprovResponses(appRequestsDeprovErrored.values(), updatable, deletable);
		}
	}

	private static void processCSSOEvents(List<ExternalOnboardingEvent__e> processableCSSO, Map<Id, Contact> requestContacts,
			Map<Id, SObject> updatableEOR, Map<Id, SObject> updatable) {
		Set<Id> failedContactIds = new Set<Id>();

		// loop through all the csso events that have been received and update records as neccessary
		for (ExternalOnboardingEvent__e listEvent : processableCSSO) {
			Id contactId = null;
			try {
				contactId = Id.valueOf(listEvent.Contact__c);
			} catch (Exception ex) {
				// nothing we can do so we skip this record
				System.debug('Skipping request since contact id is invalid on platform event.');
				continue;
			}

			// ignore this message if the contact doesn't exist
			if (!requestContacts.containsKey(contactId)) {
				System.debug('Skipping request since contact record does not exist.');
				continue;
			}

			Contact eventContact = requestContacts.get(contactId);
			Contact contactUpdate = (Contact)updatable.get(eventContact.Id);
			if(contactUpdate == null) {
				contactUpdate = new Contact(Id = eventContact.Id);
			}

			if (STATUS_ERROR.equalsIgnoreCase(listEvent.Status__c) || STATUS_EXPIRED.equalsIgnoreCase(listEvent.Status__c)) {
				// we only process this error if the user doesn't already have a CNumber OID_ID__c
				// if the OID_ID__c field has a value then this platform event is meaningless since the purpose of the CSSO flow is to get a CNumber populated on the Contact record (this population happens from an external Tibco/Camunda service)
				if (String.isEmpty(eventContact.OID_ID__c)) {
					String error = (String.isEmpty(listEvent.ResponseText__c) ? (STATUS_EXPIRED.equalsIgnoreCase(listEvent.Status__c) ? 'The registration process timed out' : 'Error occurred in registration flow') : listEvent.ResponseText__c);
					contactUpdate.BAMCSSOError__c = true;
					contactUpdate.BAMCSSOErrorMessage__c = error;
					updatable.put(contactUpdate.Id, contactUpdate);
				}

				// since the CSSO flow did not start or complete successfully then we need to cancel all the pending onboarding requests for this contact since they won't progress any further
				// we do this irrespective of whether the user has a CNumber or not
				// the business rule defined in the project was if an CSSO error is sent through then all app requests should be cancelled since the provisioning would halt
				failedContactIds.add(contactId);
			} else if (STATUS_STARTED.equalsIgnoreCase(listEvent.Status__c)) {
				// update the contact record to show that CSSO invite has kicked off
				if(eventContact.BAMInviteRequestDate__c == null) {
					contactUpdate.BAMInviteRequestDate__c = listEvent.CreatedDate;
					updatable.put(contactUpdate.Id, contactUpdate);
				}
			} else if (STATUS_FULFILLED.equalsIgnoreCase(listEvent.Status__c)) {
				// CURRENTLY, this is not propagated into SF
				// update the contact record to show that CSSO invite has been completed
				if(eventContact.BAMInviteAcceptedDate__c == null) {
					contactUpdate.BAMInviteAcceptedDate__c = listEvent.CreatedDate;
					updatable.put(contactUpdate.Id, contactUpdate);
				}
			}
		}

		// process any of the pending requests tied to these users
		if(!failedContactIds.isEmpty()) {
			List<BAMExternalOnboardingRequest__c> appRequests = [
					Select Id, Contact__c, Contact_Application__c, Contact_Application__r.Application__c, Contact_Application__r.Application__r.AppKey__c,
							Contact_Application__r.Pending_Delete__c, Contact_Application__r.Pending_Deactivation__c, Contact_Application__r.Status__c
					From BAMExternalOnboardingRequest__c
					Where Contact_Application__r.Contact__c In :failedContactIds
					And RecordTypeId = :BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID
					And Status__c = :STATUS_PENDING
			];

			for(BAMExternalOnboardingRequest__c appRequest : appRequests) {
				if(failedContactIds.contains(appRequest.Contact__c)) {
					BAMExternalOnboardingRequest__c updateableRequest = (BAMExternalOnboardingRequest__c)updatableEOR.get(appRequest.Id);
					if(updateableRequest == null) {
						updateableRequest = new BAMExternalOnboardingRequest__c(Id = appRequest.Id);
					}
					updateableRequest.Error__c = 'The user provisioning process failed';
					updateableRequest.Status__c = STATUS_ERROR;
					updatableEOR.put(appRequest.Id, updateableRequest);
				}
			}
		}
	}

	/**
	 * Based on the responses received in the platform event, process the provisioning EOR requests that were successful
	 */
	private static void tidyupFulfilledProvResponses(List<BAMExternalOnboardingRequest__c> onboardingRequests, Map<Id, SObject> updatable, Map<Id, SObject> deletable) {
		Set<Id> contactApplicationIds = new Set<Id>();

		for(BAMExternalOnboardingRequest__c onboardingRequest : onboardingRequests) {
			if(!String.isEmpty(onboardingRequest.Contact_Application__c)) {
				contactApplicationIds.add(onboardingRequest.Contact_Application__c);
			}
		}

		// grab all the contact roles and linked entities associated with the contact application record linked to the EOR record
		List<ContactRole> contactRoles = getContactRoles(contactApplicationIds);
		System.Debug('>> Found these Contact Roles for Processing: ' + contactRoles);

		// swap our dataset around so we are processing records by Contact Application
		Map<Id, List<ContactRole>> groupedRoles = new Map<Id, List<ContactRole>>();
		for(ContactRole item : contactRoles) {
			BAMContactRole__c contactRole = item.contactRole;
			if(groupedRoles.get(contactRole.ContactApplication__c) == null)
				groupedRoles.put(contactRole.ContactApplication__c, new List<ContactRole>());

			groupedRoles.get(contactRole.ContactApplication__c).add(item);
		}

		// process each onboarding request in the DML
		for(BAMExternalOnboardingRequest__c onboardingRequest : onboardingRequests) {
			List<ContactRole> existingRoles = groupedRoles.get(onboardingRequest.Contact_Application__c);

			// add the Contact Application record itself to the update list if it hasnt already been added to the updatable list
			BAMContactApplication__c contactApp = existingRoles[0].contactRole.ContactApplication__r;
			if(updatable.get(contactApp.Id) == null) {
				// we only need to accomodate movement from Inactive/Pending to Active in the provisioning success method
				if(STATUS_INACTIVE.equalsIgnoreCase(contactApp.Status__c) || STATUS_PENDING.equalsIgnoreCase(contactApp.Status__c)) {
					// a part of the tidyup is to check if the application has just been newly added or if it was previously inacitvated
					// at the start of the provisioning process, the Contact Application record will be inserted in a Pending status
					// if a contact was deactivated then it the application status would be marked as inactive
					// this is the successful completion of this process which means we can now 'Activate' the record. we also remove and temporary flags set just in case.
					updatable.put(contactApp.Id, new BAMContactApplication__c(Id = contactApp.Id, Status__c = 'Active', Pending_Delete__c = false, Pending_Deactivation__c = false));
				}
			}

			for(ContactRole existingRole : existingRoles) {
				if (existingRole.contactRole.Pending_Delete__c) {
					// a part of the tidyup is to remove roles that require removing
					// Pending Delete is set at the start of the provisioning (modify) process prior to a request going to Camunda when the user is changing from one role to another
					// NOTE: Since this role is being removed we do not update any Linked Entities associated to it
					deletable.put(existingRole.contactRole.Id, existingRole.contactRole);
				} else if (STATUS_PENDING.equalsIgnoreCase(existingRole.contactRole.Status__c) || STATUS_ACTIVE.equalsIgnoreCase(existingRole.contactRole.Status__c)) {

					if(STATUS_PENDING.equalsIgnoreCase(existingRole.contactRole.Status__c)) {
						// a part of the tidyup is to check for any role changes that were made at the start of the provisioning process
						// this would include when the BAM Admin changes the users Role from one role to another for the same application
						// this will 'Activate' the role and ensure any temporary flags are removed from it.
						updatable.put(existingRole.contactRole.Id, new BAMContactRole__c(Id = existingRole.contactRole.Id, Status__c = STATUS_ACTIVE, Pending_Delete__c = false));
					}

					// loop through all the linked entities and perform the same tidyups as per the contact role.
					if(existingRole.linkedEntities != null) {
						for (BAMLinkedEntity__c linkedEntity : existingRole.linkedEntities) {
							if (linkedEntity.Pending_Delete__c) {
								// a part of the tidyup is to remove linked entities that were removed at the start of the provisioning process
								// Pending Delete is set at the start of the provisioning (modify) process prior to a request going to Camunda
								deletable.put(linkedEntity.Id, linkedEntity);
							} else if (STATUS_PENDING.equalsIgnoreCase(linkedEntity.Status__c)) {
								// a part of the tidyup is to check for additional linked entity records that were added at the start of the provisioning process
								// this will 'Activate' the linked entity and ensure any temporary flags are removed from it.
								updatable.put(linkedEntity.Id, new BAMLinkedEntity__c(Id = linkedEntity.Id, Status__c = STATUS_ACTIVE, Pending_Delete__c = false));
							}
						}
					}
				}
			}
		}
	}

	/**
	 * Based on the responses received in the platform event, process the deprovisioning EOR requests that were successful
	 *
	 * There are 2 scenarios in which deprovisioning requests are made:
	 *  1. The user with an existing role is moved to 'No Access' (existing rules are removed permanantely)
	 *  2. The user is deactivated from the user list page (existing rules remain intact)
	 */
	private static void tidyupFulfilledDeprovResponses(List<BAMExternalOnboardingRequest__c> onboardingRequests, Map<Id, SObject> updatable, Map<Id, SObject> deletable) {

		// process each onboarding request in the DML
		for(BAMExternalOnboardingRequest__c onboardingRequest : onboardingRequests) {
			// since this was a successful deprovisioning response we need to tidyup only the contact application record.
			if(onboardingRequest.Contact_Application__r.Pending_Deactivation__c) {
				// leaving the existing rules intact but setting the status of the Contact Application record to inactive.
				updatable.put(onboardingRequest.Contact_Application__c, new BAMContactApplication__c(Id = onboardingRequest.Contact_Application__c, Status__c = STATUS_INACTIVE, Pending_Delete__c = false, Pending_Deactivation__c = false));
			} else if(onboardingRequest.Contact_Application__r.Pending_Delete__c) {
				// removing the Contact Application from the user including all it's children
				deletable.put(onboardingRequest.Contact_Application__c, new BAMContactApplication__c(Id = onboardingRequest.Contact_Application__c));
			}
		}
	}

	/**
	 * Based on the responses received in the platform event, process the deprovisioning EOR requests that failed
	 * The goal of this method is to reset the application state back to 'Active' regardless of what is pending (removing any provisioning pending records)
	 * Having a clean state after a deprov failure allows the process to be kicked off again without any issue
	 * NOTE: Without cleaning the state, there would be issues in the UI's that have special handling for 'Pending Delete' scenarios.
	 *          Prior to implementing the 'clean state' fix, we simply removed the 'Pending delete' flag which was causing problems.
	 *
	 * There are 2 scenarios in which deprovisioning requests are made:
	 *  1. The user with an existing role is moved to 'No Access' (existing rules are removed permanantely)
	 *  2. The user is deactivated from the user list page (existing rules remain intact)
	 */
	private static void tidyupErroredDeprovResponses(List<BAMExternalOnboardingRequest__c> onboardingRequests, Map<Id, SObject> updatable, Map<Id, SObject> deletable) {

		Set<Id> contactApplicationIds = new Set<Id>();
		for(BAMExternalOnboardingRequest__c onboardingRequest : onboardingRequests) {
			if(onboardingRequest.Contact_Application__c != null) {
				contactApplicationIds.add(onboardingRequest.Contact_Application__c);
			}
		}

		// process each onboarding request in the DML
		for(BAMExternalOnboardingRequest__c onboardingRequest : onboardingRequests) {
			// since this was a failed deprovisioning response we need to tidyup only the contact application record.
			// we reset the state by removing the Pending statuses on the ContactApplication record. We leave the Contact app status in tact.
			updatable.put(onboardingRequest.Contact_Application__c, new BAMContactApplication__c(Id = onboardingRequest.Contact_Application__c, Pending_Delete__c = false, Pending_Deactivation__c = false));
		}

		// group all the roles together by contact app
		Map<Id, List<ContactRole>> processableContactRoles = new Map<Id, List<ContactRole>>();
		for(ContactRole contactRole : getContactRoles(contactApplicationIds)) {
			if(processableContactRoles.get(contactRole.contactRole.ContactApplication__c) == null) {
				processableContactRoles.put(contactRole.contactRole.ContactApplication__c, new List<ContactRole>());
			}

			processableContactRoles.get(contactRole.contactRole.ContactApplication__c).add(contactRole);
		}

		// tidyup the flags and roles on child records. we need to remove pending delete and pending deactivate flags
		// to prevent any invalid data states, reset the roles back to a clean slate
		for(Id contactAppId : processableContactRoles.keySet()) {
			// only need to delete pending records if more than 1 exists
			// it's assumed if there are multiple records then at least 1 will be Active
			Integer deleteCount = 0;
			for (ContactRole currentRole : processableContactRoles.get(contactAppId)) {
				if(STATUS_PENDING.equalsIgnoreCase(currentRole.contactRole.Status__c) && processableContactRoles.get(contactAppId).size() > 1 && deleteCount < (processableContactRoles.get(contactAppId).size()-1)) {
					// make sure we leave at least 1 role in tact (if the roles are all pending)
					deletable.put(currentRole.contactRole.Id, currentRole.contactRole);
					deleteCount++;
				} else {
					// updating the last remaining record (or active records)
					updatable.put(currentRole.contactRole.Id, new BAMContactRole__c(Id = currentRole.contactRole.Id, Pending_Delete__c = false));

					// since we are updating a role and not deleting it then we need to remove all the linked entity records that are pending)
					if(currentRole.linkedEntities != null) {
						for(BAMLinkedEntity__c linkedEntity : currentRole.linkedEntities) {
							if(STATUS_PENDING.equalsIgnoreCase(linkedEntity.Status__c)) {
								deletable.put(linkedEntity.Id, linkedEntity);
							} else {
								updatable.put(linkedEntity.Id, new BAMLinkedEntity__c(Id = linkedEntity.Id, Pending_Delete__c = false));
							}
						}
					}
				}
			}
		}


//	    if(STATUS_PENDING.equalsIgnoreCase(contactRole.Status__c)) {
//		    // this is just a basic tidyup we do as a 'just in case'
//		    // there may be a pending record and an active record with a pending delete
//		    deletable.put(contactRole.Id, contactRole);
//	    }
	}

	/**
	 * Reorders the list to reduce number of chunks since if you reach a maximum of 10 chunks for updates across multiple objects, and error will be thrown
	 * TODO: This should be refactored and stored in a more generic class
	 */
	public static Map<Id, Sobject> reorderUnitsOfWork(Map<Id, Sobject> unitsOfWork) {
		return reorderUnitsOfWork(unitsOfWork, new List<String>());
	}

	/**
	 * Reorders the list to reduce number of chunks since if you reach a maximum of 10 chunks for updates across multiple objects, and error will be thrown
	 * TODO: This should be refactored and stored in a more generic class
	 */
	public static Map<Id, Sobject> reorderUnitsOfWork(Map<Id, Sobject> unitsOfWork, List<String> objectPriority) {
		Map<Id, Sobject> output = new Map<Id, Sobject>();
		Map<String, Map<Id, Sobject>> reorderedWork = new Map<String, Map<Id, Sobject>>();
		for(Id recordId : unitsOfWork.keySet()) {
			String objectName = CommonUtils.getObjectAPINameByRecordId(recordId);
			if(reorderedWork.get(objectName) == null)
				reorderedWork.put(objectName, new Map<Id, Sobject>());

			reorderedWork.get(objectName).put(recordId, unitsOfWork.get(recordId));
		}

		for(String objectName : objectPriority) {
			if(reorderedWork.get(objectName) != null) {
				output.putAll(reorderedWork.get(objectName));
				reorderedWork.remove(objectName);
			}
		}

		for(String objectName : reorderedWork.keySet()) {
			output.putAll(reorderedWork.get(objectName));
		}

		return output;
	}


	/**
	 * Remove any stale responses received that are not from the LATEST request to minimise unintended results
	 * In a happy path scenario these should not be needed, but it's here just in case
	 */
	public static Map<Id, BAMExternalOnboardingRequest__c> filterOnboardingRequests(Map<Id, BAMExternalOnboardingRequest__c> onboardingRequests) {
		Map<Id, BAMExternalOnboardingRequest__c> output = new Map<Id, BAMExternalOnboardingRequest__c>();
		Set<Id> contactApplicationIds = new Set<Id>();
		for(BAMExternalOnboardingRequest__c onboardingRequest : onboardingRequests.values()) {
			if(!String.isEmpty(onboardingRequest.Contact_Application__c)) {
				contactApplicationIds.add(onboardingRequest.Contact_Application__c);
			}
		}

		Map<Id, BAMContactApplication__c> contactApps = new Map<Id, BAMContactApplication__c>([
			Select Id, (Select Id From BAM_External_Onboarding_Requests__r
			Where RecordTypeId = :BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID
			Order By CreatedDate Desc Limit 1)
			From BAMContactApplication__c
			Where Id In: contactApplicationIds
		]);
		for(BAMExternalOnboardingRequest__c onboardingRequest : onboardingRequests.values()) {
			if(contactApps.get(onboardingRequest.Contact_Application__c) != null) {
				List<BAMExternalOnboardingRequest__c> childRequests = contactApps.get(onboardingRequest.Contact_Application__c).BAM_External_Onboarding_Requests__r;
				if(childRequests != null && childRequests.size() > 0 && childRequests[0].Id == onboardingRequest.Id) {
					output.put(onboardingRequest.Id, onboardingRequest);
				}
			}
		}

		return output;
	}


	/**
	 * split up the contact role query into multiple queries because of this error:
	 * System.QueryException:Aggregate query has too many rows for direct assignment, use FOR loop
	 */
	private static List<ContactRole> getContactRoles(Set<Id> contactAppIds) {

		Map<Id, List<BAMLinkedEntity__c>> mappedLinkedEntities = new Map<Id, List<BAMLinkedEntity__c>>();
		for(BAMLinkedEntity__c linkedEntity : [Select Id, Pending_Delete__c, Status__c, ContactRole__c
		From BAMLinkedEntity__c
		Where ContactRole__r.ContactApplication__c In :contactAppIds]) {

			if(mappedLinkedEntities.get(linkedEntity.ContactRole__c) == null) {
				mappedLinkedEntities.put(linkedEntity.ContactRole__c, new List<BAMLinkedEntity__c>());
			}
			mappedLinkedEntities.get(linkedEntity.ContactRole__c).add(linkedEntity);

		}

		List<BAMContactRole__c> contactRoles = new List<BAMContactRole__c>([
				Select Id, ContactApplication__c, ContactApplication__r.Id, ContactApplication__r.Pending_Delete__c,
						ContactApplication__r.Pending_Deactivation__c, ContactApplication__r.Status__c,
						Status__c, Pending_Delete__c
				From BAMContactRole__c
				Where ContactApplication__c In :contactAppIds
		]);

		List<ContactRole> output = new List<ContactRole>();
		for(BAMContactRole__c role : contactRoles) {
			ContactRole outputRole = new ContactRole();
			outputRole.contactRole = role;
			if(mappedLinkedEntities.get(role.Id) != null) {
				outputRole.linkedEntities = mappedLinkedEntities.get(role.Id);
			}
			output.add(outputRole);
		}

		return output;
	}

	public static String truncateTo(String text, Integer maxLength) {
		if(String.isEmpty(text)) {
			return '';
		} else {
			return text.substring(0, Math.min(text.length(), maxLength));
		}
	}

	/**
	 * Sort the events in the correct processable order
	 * Started, Error, Fulfilled
	 */
	public class EventWrapper implements Comparable {
		public ExternalOnboardingEvent__e event;

		// Constructor
		public EventWrapper(ExternalOnboardingEvent__e event) {
			this.event = event;
		}

		// Compare opportunities based on the opportunity amount.
		public Integer compareTo(Object compareTo) {
			EventWrapper compareToObject = (EventWrapper)compareTo;

			Integer returnValue = 0;
			if (ONBOARDING_REQUEST_SORT_ORDER.get(event.Status__c) != null && ONBOARDING_REQUEST_SORT_ORDER.get(compareToObject.event.Status__c) != null && ONBOARDING_REQUEST_SORT_ORDER.get(event.Status__c) > ONBOARDING_REQUEST_SORT_ORDER.get(compareToObject.event.Status__c)) {
				returnValue = 1;
			} else if (ONBOARDING_REQUEST_SORT_ORDER.get(event.Status__c) != null && ONBOARDING_REQUEST_SORT_ORDER.get(compareToObject.event.Status__c) != null && ONBOARDING_REQUEST_SORT_ORDER.get(event.Status__c) < ONBOARDING_REQUEST_SORT_ORDER.get(compareToObject.event.Status__c)) {
				returnValue = -1;
			} else if(ONBOARDING_REQUEST_SORT_ORDER.get(event.Status__c) == null) {
				returnValue = 1;
			} else if(ONBOARDING_REQUEST_SORT_ORDER.get(compareToObject.event.Status__c) == null) {
				returnValue = -1;
			}

			return returnValue;
		}
	}

	private class ContactRole {
		public BAMContactRole__c contactRole;
		public List<BAMLinkedEntity__c> linkedEntities;
	}
}