/**
 * @description Application Module to handle StarTrack billing account creation platform events containing provisioning results
 *			  from billing accounts master system (currently StarTrack billing accounts are mastered in TEAM).
 *
 *			  On receiving success status, new billing accounts are created in Salesforce and relevant related records
 *			  are updated depending on it's context. For newly created billing accounts, an async process is used to
 *			  execute following post commit actions:
 *			  1. Populate self lookup fields on billing account object (LeaderAccount__c, and PAYER_ACCOUNT_ID__c) when related
 *				 records are also newly inserted by this module in current transaction.
 *
 *			  On receiving error status, updates the relevant request records and bell notifications are sent to users on
 *			  error response.
 *
 *			  Design Documentation:
 *			  - Response data mapping [https://australiapost.jira.com/wiki/spaces/STP/pages/2823521265/Design+OB010+Response+Data+Map]
 *			  - Notifications [https://australiapost.jira.com/wiki/spaces/STP/pages/2829255439/Design+Custom+Notification]
 *			  - State transition diagrams for OB010 [https://australiapost.jira.com/wiki/spaces/STP/pages/2925135949/Design+OB010+TEAM+State+Model]
 *
 * @author Ranjeewa Silva
 * @date 2023-11-24
 * @test CreateSTBillingAccEvtHandlerModule_Test
 * @changelog
 * 2023-11-24 - Ranjeewa Silva - Created.
 */
public inherited sharing class CreateSTBillingAccountEventHandlerModule extends ApplicationModule {

	// new billing accounts registered with uow to be inserted when uow is committed.
	// key - billing account number (LEGACY_ID__c), value - new sobject record
	private static final Map<String, Billing_Account__c> newBillingAccounts = new Map<String, Billing_Account__c>();

	// mapping of request dsr id to billing account number of new leader accounts.
	// key - deal support request id, value - billing account number (LEGACY_ID__c) of the new leader billing account.
	private static final Map<Id, String> dsrLeaderBillingAccountNumberMapping = new Map<Id, String>();

	// id of DSR record type 'Customer Onboarding'. for each successful sub account, a new 'Customer Onboarding' DSR is
	// created for manual surcharge setup and activation.
	private static final Id CUSTOMER_ONBOARDING_DSR_RECORDTYPEID {
		get {
			if (CUSTOMER_ONBOARDING_DSR_RECORDTYPEID == null) {
				Map<Id, RecordType> recordTypesMap = RecordTypesSelector.newInstance().selectByDeveloperName(String.valueOf(Deal_Support_Request__c.SObjectType), new Set<String>{'Deal_Enablement_Centre'});
				if (!recordTypesMap.isEmpty()) {
					CUSTOMER_ONBOARDING_DSR_RECORDTYPEID = recordTypesMap.values()[0].Id;
				}
			}
			return CUSTOMER_ONBOARDING_DSR_RECORDTYPEID;
		}
		set;
	}

	// organisation's referencing these holding roles are to be updated on successful leader account creation
	private static final Set<String> ORGANISATION_HOLDING_ROLES_TO_MIGRATE = new Set<String>{'Known', 'Prospect'};

	// holding role reference for 'New Account'. any existing organisation's that still reference holding roles
	// specified in ORGANISATION_HOLDING_ROLES_TO_MIGRATE above, are to be updated to 'New Account' holding role on successful
	// leader account creation.
	private static final Holding_Role_Reference__c NEW_ACCOUNT_HOLDING_ROLE {
		get {
			if (NEW_ACCOUNT_HOLDING_ROLE == null) {
				Map<Id, Holding_Role_Reference__c> holdingRoles = HoldingReferenceRoleSelector.newInstance(1).selectByName('New Accounts');
				NEW_ACCOUNT_HOLDING_ROLE = (!holdingRoles.isEmpty() ? holdingRoles.values()[0] : new Holding_Role_Reference__c());
			}
			return NEW_ACCOUNT_HOLDING_ROLE;
		}
		set;
	}

	// custom metadata holding billing account configuration parameters for StarTrack accounts
	@TestVisible private static final BillingAccountCreationConfiguration__mdt BILLING_ACCOUNT_CREATION_CONFIGURATION {
		get {
			if (BILLING_ACCOUNT_CREATION_CONFIGURATION == null) {
				BILLING_ACCOUNT_CREATION_CONFIGURATION = BillingAccountCreationConfiguration__mdt.getInstance('StarTrack_TEAM');
			}
			return BILLING_ACCOUNT_CREATION_CONFIGURATION;
		}
		set;
	}

	// deal support request queue to assign new DSR record requesting surcharge setup and manual activation of
	// newly provisioned sub account.
	private static final Group SURCHARGE_SETUP_DSR_OWNER_QUEUE {
		get {
			if (SURCHARGE_SETUP_DSR_OWNER_QUEUE == null) {
				List<Group> groups = ((GroupsSelector) GroupsSelector.newInstance(1).setFieldOverrides(new Set<SObjectField>{
						Group.Id, Group.DeveloperName
				})).selectByGroupTypeAndDeveloperName(new Set<String>{'queue'}, new Set<String>{BILLING_ACCOUNT_CREATION_CONFIGURATION?.SurchargeSetupDSRQueue__c}).values();
				SURCHARGE_SETUP_DSR_OWNER_QUEUE = (!groups.isEmpty() ? groups[0] : new Group());
			}
			return SURCHARGE_SETUP_DSR_OWNER_QUEUE;
		}
		set;
	}

	public CreateSTBillingAccountEventHandlerModule() {
		getTriggerEvents().enableAfterInsert();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			if (!records.isEmpty()) {
				// iterate over the list of platform events and collect Salesforce record Ids referenced in platform events
				Set<Id> externalOnboardingRequestIds = new Set<Id>();
				Set<Id> dealSupportRequestIds = new Set<Id>();
				Set<Id> organisationIds = new Set<Id>();
				Set<Id> subAccountRequestIds = new Set<Id>();
				Set<Id> existingLeaderBillingAccountIds = new Set<Id>();
				for (BillingAccountCreationEvent__e event: (List<BillingAccountCreationEvent__e>) records) {
					if (String.isNotBlank(event.Transaction_Id__c)) {
						// each platform event is expected to specify integration transaction id (Id of BAMExternalOnboardingRequest__c)
						externalOnboardingRequestIds.add(event.Transaction_Id__c);
					}
					if (String.isNotBlank(event.Request_Object_Id__c)) {
						if (isRecordIdOfType(event.Request_Object_Id__c, Deal_Support_Request__c.SObjectType)) {
							// when request is initiated from a DSR record in Salesforce (i.e. in DSR flow), Id of the DSR record is specified
							// as the event.Request_Object_ID__c.
							dealSupportRequestIds.add(event.Request_Object_Id__c);
						} else {
							// when request is initiated from an existing leader billing account in Salesforce (i.e. in BA flow),
							// Salesforce Id of the leader billing account record is specified as the event.Request_Object_ID__c.
							existingLeaderBillingAccountIds.add(event.Request_Object_Id__c);
						}
					}

					if (String.isNotBlank(event.Organisation_Record_Id__c)) {
						// this is the parent customer Organisation (Account) for billing account.
						organisationIds.add(event.Organisation_Record_Id__c);
					}

					if (String.isNotBlank(event.Sub_Account_Request_Id__c)) {
						// when this is an event related to a sub account,  event.Sub_Account_Request_Id__c specify the
						// Id of APT_Sub_Account__c containing the details of the sub account request.
						subAccountRequestIds.add(event.Sub_Account_Request_Id__c);
					}
				}

				handleBillingAccountCreationEvents((List<BillingAccountCreationEvent__e>) records, externalOnboardingRequestIds, dealSupportRequestIds, organisationIds, subAccountRequestIds, existingLeaderBillingAccountIds, uow);
			}
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales', CreateSTBillingAccountEventHandlerModule.class.getName(),
					'onAfterInsert', 'BillingAccountCreationEventTrigger', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Handle billing account creation platform events received from camunda.
	 *
	 * @param events list of billing account creation events
	 * @param externalOnboardingRequestIds external onboarding request ids referenced in the events
	 * @param dealSupportRequestIds deal support request ids referenced in the events
	 * @param organisationIds organisation ids referenced in the events
	 * @param subAccountRequestIds sub account request ids referenced in the events
	 * @param existingLeaderBillingAccountIds leader billing account ids related to sub account request ids referenced in events
	 * @param uow unit of work instance supplied by the application module framework
	 */
	private void handleBillingAccountCreationEvents(List<BillingAccountCreationEvent__e> events, Set<Id> externalOnboardingRequestIds, Set<Id> dealSupportRequestIds, Set<Id> organisationIds, Set<Id> subAccountRequestIds, Set<Id> existingLeaderBillingAccountIds, ApplicationUnitOfWork uow) {
		// query salesforce records referenced in the events.
		Map<Id, Deal_Support_Request__c> dealSupportRequests = selectDealSupportRequests(dealSupportRequestIds);
		Map<Id, BAMExternalOnboardingRequest__c> externalOnboardingRequests = selectExternalOnboardingRequests(externalOnboardingRequestIds);
		Map<Id, Account> organisations = selectOrganisations(organisationIds);
		Map<Id, APT_Sub_Account__c> subAccountRequests = selectSubAccountRequests(subAccountRequestIds);
		Map<Id, Pick_Up_Location__c> pickupLocations = selectPrimaryPickupLocations(dealSupportRequests.values());
		Map<Id, Billing_Account__c> existingLeaderBillingAccounts = selectBillingAccounts(existingLeaderBillingAccountIds);

		// external onboarding request records containing updates from processing platform events. these are registered with
		// unit of work at the end of processing all events. note that one external onboarding request record could be referenced by more than one event.
		Map<Id, BAMExternalOnboardingRequest__c> updatableExternalOnboardingRequests = new Map<Id, BAMExternalOnboardingRequest__c>();
		// deal support request records containing updates from processing platform events. these are registered with
		// unit of work at the end of processing all events. note that one deal support request record could be referenced by more than one event.
		Map<Id, Deal_Support_Request__c> updatableDealSupportRequests = new Map<Id, Deal_Support_Request__c>();

		// populating self-lookups on newly created billing accounts (when related billing account is also newly inserted)
		// are implemented in an async worker as currently application module/unit of work framework does not provide a
		// way for the modules to execute post commit actions when the ids of newly inserted records are available.
		// below is a list of async worker parameters collected during processing. will be registered for async work at the
		// end of processing events.
		List<StarTrackBillingAccountPostCommitWorkerParam> postCommitAsyncWorkerParams = new List<StarTrackBillingAccountPostCommitWorkerParam>();

		// collect billing account creation results (leader accounts and sub accounts) for external onboarding requests
		// sent from Salesforce. bell notifications to end users will be generated per each onboarding request summarising
		// success / error results.
		Map<Id, ExternalOnboardingResult> externalOnboardingResults = new Map<Id, ExternalOnboardingResult>();

		for (BillingAccountCreationEvent__e event: events) {
			// is the event related to a leader account. used throughout the processing of this event.
			Boolean isLeaderAccount = String.isBlank(event.Sub_Account_Request_Id__c);

			// get the external onboarding request referenced in this event. this is the version currently persisted in database.
			BAMExternalOnboardingRequest__c externalOnboardingRequest = externalOnboardingRequests.get(event.Transaction_Id__c);
			if (externalOnboardingRequest != null) {
				// get an updatable external onboarding request based on this event. if we have an updatable instance from
				// a previous event, we keep updating the same updatable instance. if not, create a new updatable instance
				// based on the current event and the version retrieved from database.
				BAMExternalOnboardingRequest__c updatableExternalOnboardingRequest = getUpdatableExternalOnboardingRequest(event, updatableExternalOnboardingRequests.get(event.Transaction_Id__c), externalOnboardingRequest);
				if (!updatableExternalOnboardingRequests.containsKey(externalOnboardingRequest.Id)) {
					// this is the first time this external onboarding request record is updated during current batch of events.
					updatableExternalOnboardingRequests.put(updatableExternalOnboardingRequest.Id, updatableExternalOnboardingRequest);
				}
			}

			// get the deal support request referenced in this event. this is the version currently persisted in database.
			Deal_Support_Request__c dealSupportRequest = dealSupportRequests.get(event.Request_Object_Id__c);
			if (dealSupportRequest != null) {
				// get an updatable deal support request based on this event. if we have an updatable instance from
				// a previous event, we keep updating the same updatable instance. if not, create a new updatable instance
				// based on the current event and the version retrieved from database.
				Deal_Support_Request__c updatableDealSupportRequest = getUpdatableDealSupportRequest(event, isLeaderAccount, updatableDealSupportRequests.get(dealSupportRequest.Id));
				if (!updatableDealSupportRequests.containsKey(dealSupportRequest.Id)) {
					// this is the first time this deal support request record is updated during current batch of events.
					updatableDealSupportRequests.put(dealSupportRequest.Id, updatableDealSupportRequest);
				}
			}

			// check if we already have a results instance for the transaction id. if we have received a prior event
			// with the same transaction id in current batch, we should already have a results instance. if not, create
			// a new results instance as this is the first event (in current batch) for this transaction id.
			ExternalOnboardingResult externalOnboardingResult = externalOnboardingResults.get(event.Transaction_Id__c);
			if (externalOnboardingResult == null && externalOnboardingRequest != null) {
				// this event is the first in current batch containing this transaction id. create a new results instance.
				// grab the name of the record where the request was initiated from. this is either a DSR record or
				// an existing Leader billing account.
				String requestObjectName = (dealSupportRequest != null ? dealSupportRequest.Name : existingLeaderBillingAccounts.get(event.Request_Object_Id__c)?.LEGACY_ID__c);
				externalOnboardingResult = new ExternalOnboardingResult(externalOnboardingRequest, event.Request_Object_Id__c, requestObjectName, organisations.get(event.Organisation_Record_Id__c)?.Name);
				externalOnboardingResults.put(event.Transaction_Id__c, externalOnboardingResult);
			}

			if ('Success'.equalsIgnoreCase(event.Status__c)) {
				StarTrackBillingAccountPostCommitWorkerParam postCommitWorkerParam = handleBillingAccountProvisionSuccessEvent(event, isLeaderAccount, organisations.get(event.Organisation_Record_Id__c), dealSupportRequest, subAccountRequests.get(event.Sub_Account_Request_Id__c), pickupLocations.get(dealSupportRequest?.Opportunity__r?.Primary_Pick_Up_Location__c), externalOnboardingResult, uow);
				if (postCommitWorkerParam != null) {
					postCommitAsyncWorkerParams.add(postCommitWorkerParam);
				}
			} else if ('Error'.equalsIgnoreCase(event.Status__c)) {
				handleBillingAccountProvisionErrorEvent(event, isLeaderAccount, organisations.get(event.Organisation_Record_Id__c), dealSupportRequest, subAccountRequests.get(event.Sub_Account_Request_Id__c), externalOnboardingResult, uow);
			}
		}

		if (!updatableExternalOnboardingRequests.isEmpty()) {
			// we have updatable external onboarding requests. register them with unit of work as dirty records.
			uow.registerDirty(updatableExternalOnboardingRequests.values(), false, CreateSTBillingAccountEventHandlerModule.class.getName() + ':handleBillingAccountProvisionEvent()');
		}

		if (!updatableDealSupportRequests.isEmpty()) {
			// we have updatable deal support requests. register them with unit of work as dirty records.
			uow.registerDirty(updatableDealSupportRequests.values(), false, CreateSTBillingAccountEventHandlerModule.class.getName() + ':handleBillingAccountProvisionEvent()');
		}

		if (!dsrLeaderBillingAccountNumberMapping.isEmpty()) {
			// we have newly provisioned leader billing accounts. need to check if there are existing sub account requests
			// still in 'Draft' status linked to charge account requests corresponding to these newly created leader accounts.
			// this is possible as there is a limit on number of sub account requests finalized and included in the provisioning
			// request with the leader account in DSR flow.
			// if we find such sub account requests, we need to update the billing account reference on them to the newly
			// provisioned leader billing account. this is to ensure these sub account requests can be submitted for provisioning
			// via billing account flow.
			updateSubAccountRequestsOnDSRNotSubmittedForProvisioning(dealSupportRequests, uow);
		}

		if (!postCommitAsyncWorkerParams.isEmpty()) {
			// we have post commit work that needs to be registered as async work.
			uow.registerAsyncWork(new ApplicationUnitOfWork.AsyncStagingWorker(CreateStarTrackBillingAccountPostCommitAsyncWorker.class, postCommitAsyncWorkerParams));
		}

		if (!externalOnboardingResults.isEmpty()) {
			// notify end users on billing account onboarding results.
			sendCustomNotifications(externalOnboardingResults.values());
		}
	}

	/**
	 * Handle billing account creation success platform event received from camunda.
	 *
	 * @param event success event received from Camunda
	 * @param isLeaderAccount indicates if this event is related to a leader billing account
	 * @param organisation customer organisation (account) record referenced in the event
	 * @param dealSupportRequest deal support request record referenced in the event. pass null if not available.
	 * @param subAccountRequest sub account request record referenced in the event. pass null if not available.
	 * @param pickupLocation pickup location capturing the physical address relevant to the leader billing account in DSR flow. pass null if not available.
	 * @param externalOnboardingResult onboarding results instance to update with this success result.
	 * @param uow unit of work instance
	 *
	 * @return Parameters to async worker process to execute post commit actions.
	 */
	private StarTrackBillingAccountPostCommitWorkerParam handleBillingAccountProvisionSuccessEvent(BillingAccountCreationEvent__e event, Boolean isLeaderAccount, Account organisation, Deal_Support_Request__c dealSupportRequest, APT_Sub_Account__c subAccountRequest, Pick_Up_Location__c pickupLocation, ExternalOnboardingResult externalOnboardingResult, ApplicationUnitOfWork uow) {
		// get a new billing account instance
		Billing_Account__c newBillingAccount = newBillingAccount(event, isLeaderAccount, organisation, dealSupportRequest, subAccountRequest, pickupLocation);
		// trace id to supply into uow register operations which helps to trace back to the source in the event of any errors.
		String uowSourceTraceId = CreateSTBillingAccountEventHandlerModule.class.getName() + '.handleBillingAccountProvisionSuccessEvent';
		uow.registerNew(newBillingAccount, false, uowSourceTraceId);

		// store new billing account instance for future reference while processing current batch of events.
		newBillingAccounts.put(newBillingAccount.LEGACY_ID__c, newBillingAccount);

		if (dealSupportRequest != null && isLeaderAccount) {
			// this event is related to a leader billing account in DSR flow.

			// populate the dsr id to leader billing account number mapping for future reference while processing current batch of events.
			dsrLeaderBillingAccountNumberMapping.put(dealSupportRequest.Id, newBillingAccount.LEGACY_ID__c);

			// set charge account request status and populate billing account reference.
			APT_Charge_Account__c chargeAccountRequest = new APT_Charge_Account__c(Id=dealSupportRequest?.APT_Contract__r?.Apttus_QPComply__RelatedProposalId__r?.APT_Credit_Assessment__r?.APT_Charge_Account__c);
			chargeAccountRequest.Status__c = 'Completed';
			uow.registerDirty(chargeAccountRequest, false, uowSourceTraceId);
			uow.registerRelationship(chargeAccountRequest, APT_Charge_Account__c.Billing_Account__c, newBillingAccount);

			// populate billing account reference on apttus contract.
			Apttus__APTS_Agreement__c updatableApttusContract = new Apttus__APTS_Agreement__c(Id=dealSupportRequest.APT_Contract__c);
			uow.registerDirty(updatableApttusContract, false, uowSourceTraceId);
			uow.registerRelationship(updatableApttusContract, Apttus__APTS_Agreement__c.Billing_Account__c, newBillingAccount);

			// check if Organisation_Role__c linked to the customer organisation (account) need to be updated. if customer
			// organisation (account) is still having a role of 'Known' or 'Prospect' it need to be updated to 'Customer' now
			// with the new leader billing account created.
			Organisation_Role__c updatableOrganisationRole = getUpdatableOrganisationRole(organisation);
			if (updatableOrganisationRole != null) {
				uow.registerDirty(updatableOrganisationRole, false, uowSourceTraceId);
			}

			// as per the design (see references in class header), inheriting below from legacy code. it is unclear why this is required?
			if (ORGANISATION_HOLDING_ROLES_TO_MIGRATE.contains(organisation.Holding_Role_Reference__r?.Name) && NEW_ACCOUNT_HOLDING_ROLE?.Id != null) {
				Account updatableOrganisation = new Account(Id=organisation.Id, Holding_Role_Reference__c=NEW_ACCOUNT_HOLDING_ROLE.Id);
				uow.registerDirty(updatableOrganisation, false, uowSourceTraceId);
			}

			// add billing account provision 'success' result to the external onboarding results summary.
			externalOnboardingResult.addBillingAccountProvisionResult(chargeAccountRequest, event.Billing_Account_Number__c);
		}

		if (subAccountRequest != null) {
			// this event is related to a sub account request. Note that this could have been initiated in either of the two flows.

			APT_Sub_Account__c updatableSubAccountRequest = getUpdatableSubAccountRequest(event);
			uow.registerDirty(updatableSubAccountRequest, false, uowSourceTraceId);

			// for each successful sub account, new 'Customer Onboarding' DSR is to be created for surcharge setup and activation.
			// note that this isn't required for leader accounts.
			Deal_Support_Request__c surchargeSetupAndActivationDSR = newDSRForSurchargeSetupAndActivation(event, organisation, subAccountRequest);
			uow.registerNew(surchargeSetupAndActivationDSR, false, uowSourceTraceId);
			uow.registerRelationship(surchargeSetupAndActivationDSR, Deal_Support_Request__c.Billing_Account__c, newBillingAccount);

			// add billing account provision 'success' result to the external onboarding results summary.
			externalOnboardingResult.addBillingAccountProvisionResult(subAccountRequest, event.Billing_Account_Number__c);
		}

		// get an instance of async worker parameters to be registered with unit of work for async processing. async processing
		// is required in below scenario:
		//  - populate self lookups on new billing account instance (LeaderAccount__c and PAYER_ACCOUNT_ID__c). if related billing accounts are
		//	  also new this needs to be done after the related records are inserted into the database. Apex does not allow
		//	  populating self lookup fields by reference (i.e. via '__r') when referenced records are also new.
		//	  see https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_dml_limitations.htm
		return processSelfLookupsForNewBillingAccount(event, newBillingAccount);
	}

	/**
	 * Handle billing account creation error platform event received from camunda. Notifications to end users(bell notification)
	 * are also triggered by this method.
	 *
	 * @param event error event received from Camunda
	 * @param isLeaderAccount indicates if this event is related to a leader billing account
	 * @param organisation customer organisation (account) record referenced in the event
	 * @param dealSupportRequest deal support request record referenced in the event. pass null if not available.
	 * @param subAccountRequest sub account request record referenced in the event. pass null if not available.
	 * @param externalOnboardingResult external onboarding result instance to update with this error result.
	 * @param uow unit of work instance
	 */
	private void handleBillingAccountProvisionErrorEvent(BillingAccountCreationEvent__e event, Boolean isLeaderAccount, Account organisation, Deal_Support_Request__c dealSupportRequest, APT_Sub_Account__c subAccountRequest, ExternalOnboardingResult externalOnboardingResult, ApplicationUnitOfWork uow) {
		if (isLeaderAccount) {
			// this event is related to a leader billing account in DSR flow.

			// set charge account request status to 'Error'.
			APT_Charge_Account__c chargeAccountRequest = new APT_Charge_Account__c(Id=dealSupportRequest.APT_Contract__r?.Apttus_QPComply__RelatedProposalId__r?.APT_Credit_Assessment__r?.APT_Charge_Account__c);
			chargeAccountRequest.Status__c = 'Error';
			uow.registerDirty(chargeAccountRequest, false, CreateSTBillingAccountEventHandlerModule.class.getName() + ':handleBillingAccountProvisionErrorEvent');

			// add billing account provision 'error' result to the external onboarding results summary.
			externalOnboardingResult.addBillingAccountProvisionResult(chargeAccountRequest, null);

		} else {
			// this event is related to a sub account request. Note that this could have been initiated in either of the two flows.

			APT_Sub_Account__c updatableSubAccountRequest = getUpdatableSubAccountRequest(event);
			if (dealSupportRequest != null) {
				// this is a sub account creation error in DSR flow. we need to update billing account lookup on sub account request
				// if leader account has been provisioned successfully.
				String leaderAccountNumber = dsrLeaderBillingAccountNumberMapping.get(dealSupportRequest.Id);
				if (String.isNotBlank(leaderAccountNumber)) {
					uow.registerRelationship(updatableSubAccountRequest, APT_Sub_Account__c.APT_Billing_Account__c, newBillingAccounts.get(leaderAccountNumber));
				} else if (String.isNotBlank(dealSupportRequest.Billing_Number__c)) {
					leaderAccountNumber = dealSupportRequest.Billing_Number__c;
					updatableSubAccountRequest.APT_Billing_Account__r = new Billing_Account__c(LEGACY_ID__c=leaderAccountNumber);
				}
			}
			uow.registerDirty(updatableSubAccountRequest, false, CreateSTBillingAccountEventHandlerModule.class.getName() + ':handleBillingAccountProvisionErrorEvent');

			// add billing account provision 'error' result to the external onboarding results summary.
			externalOnboardingResult.addBillingAccountProvisionResult(subAccountRequest, null);
		}
	}

	/**
	 * Create a new instance of billing account from the details of platform event and other records in Salesforce
	 *
	 * @param event success event received from Camunda
	 * @param isLeaderAccount indicates if this event is related to a leader billing account
	 * @param organisation customer organisation (account) record referenced in the event
	 * @param dealSupportRequest deal support request record referenced in the event. pass null if not available.
	 * @param subAccountRequest sub account request record referenced in the event. pass null if not available.
	 * @param pickupLocation pickup location capturing the physical address relevant to the leader billing account in DSR flow. pass null if not available.
	 *
	 * @return new billing account (Billing_Account__c)
	 */
	private Billing_Account__c newBillingAccount(BillingAccountCreationEvent__e event, Boolean isLeaderAccount, Account organisation, Deal_Support_Request__c dealSupportRequest, APT_Sub_Account__c subAccountRequest, Pick_Up_Location__c pickupLocation) {

		Billing_Account__c newBillingAccount = new Billing_Account__c();
		newBillingAccount.Source_System__c = event.Source_System__c;
		newBillingAccount.Organisation__c = event.Organisation_Record_Id__c;
		newBillingAccount.Name = event.Billing_Account_Name__c;
		newBillingAccount.LEGACY_ID__c = event.Billing_Account_Number__c;
		newBillingAccount.Credit_Person_Phone__c = event.Credit_Officer_Phone__c;
		newBillingAccount.Credit_Person_Code__c = event.Credit_Person_Code__c;
		newBillingAccount.Credit_Person__c = event.Credit_Person__c;
		newBillingAccount.Is_this_a_sub_account__c = (isLeaderAccount ? 'No': 'Yes');

		// below fields are sourced from salesforce records. given that Salesforce is not the master system for billing accounts,
		// these fields should ideally be included in the platform event Salesforce receives from Camunda.
		newBillingAccount.Street__c = (isLeaderAccount ? organisation?.BillingStreet : subAccountRequest?.APT_Postal_Address_Street_Name__c);
		newBillingAccount.Suburb__c = (isLeaderAccount ? organisation?.BillingCity : subAccountRequest?.APT_Postal_Address_Suburb__c);
		newBillingAccount.Postal_Code__c = (isLeaderAccount ? organisation?.BillingPostalCode : subAccountRequest?.APT_Postal_Address_Street_Postcode__c);
		newBillingAccount.State__c = (isLeaderAccount ? organisation?.BillingState : subAccountRequest?.APT_Postal_Address_State__c);
		newBillingAccount.Country__c = (isLeaderAccount ? organisation?.BillingCountry : subAccountRequest?.APT_Postal_Address_Country_Code__c);

		newBillingAccount.PhysicalStreet__c = (isLeaderAccount ? pickupLocation?.Address__c : subAccountRequest?.APT_Street_Address_Street_Name__c);
		newBillingAccount.PhysicalSuburb__c = (isLeaderAccount ? pickupLocation?.Suburb__c : subAccountRequest?.APT_Street_Address_Suburb__c);
		newBillingAccount.PhysicalPostalCode__c = (isLeaderAccount ? pickupLocation?.PostCode__c : subAccountRequest?.APT_Street_Address_Street_Postcode__c);
		newBillingAccount.PhysicalState__c = (isLeaderAccount ? pickupLocation?.State__c : subAccountRequest?.APT_Street_Address_State__c);
		newBillingAccount.PhysicalCountry__c = (isLeaderAccount ? null : subAccountRequest?.APT_Street_Address_Country_Code__c);

		newBillingAccount.Phone_Number__c = isLeaderAccount ? getPhoneNumber(dealSupportRequest?.APT_contract__r?.Apttus__Primary_Contact__r) : getPhoneNumber(subAccountRequest?.SubAccountContact__r);
		newBillingAccount.Fax_Number__c = isLeaderAccount ? dealSupportRequest?.APT_contract__r?.Apttus__Primary_Contact__r.Fax : subAccountRequest?.SubAccountContact__r?.Fax;
		newBillingAccount.Email__c = isLeaderAccount ? dealSupportRequest?.APT_contract__r?.Apttus__Primary_Contact__r.Email : subAccountRequest?.APT_Sub_Account_Contact_Email_Address__c;

		newBillingAccount.SiteContactFirstName__c = isLeaderAccount ? dealSupportRequest?.APT_contract__r?.Apttus__Primary_Contact__r?.FirstName : subAccountRequest?.SubAccountContact__r?.FirstName;
		newBillingAccount.SiteContactLastName__c = isLeaderAccount ? dealSupportRequest?.APT_contract__r?.Apttus__Primary_Contact__r?.LastName : subAccountRequest?.SubAccountContact__r?.LastName;
		newBillingAccount.SiteContactTelephone__c = isLeaderAccount ? getPhoneNumber(dealSupportRequest?.APT_contract__r?.Apttus__Primary_Contact__r) : getPhoneNumber(subAccountRequest?.SubAccountContact__r);
		newBillingAccount.SiteContactEmail__c = isLeaderAccount ? dealSupportRequest?.APT_contract__r?.Apttus__Primary_Contact__r?.Email :  subAccountRequest?.SubAccountContact__r?.Email;

		newBillingAccount.ABN__c = organisation?.ABN__c;
		if (isLeaderAccount) {
			// this is leader account (DSR flow)
			newBillingAccount.ACN__c = organisation?.ACN__c;
			newBillingAccount.Business_Solutions_Contact__c = organisation?.Primary_Business_Solutions_Contact__c;
			newBillingAccount.Credit_Limit__c = dealSupportRequest?.APT_Contract__r?.Apttus_QPComply__RelatedProposalId__r?.APT_Credit_Assessment__r?.StarTrack_Proposed_for_New_Account__c;
		} else {
			// sub account (follower / offspring) both DSR flow and BA flow
			newBillingAccount.Customer_Name_2__c = subAccountRequest?.APT_Account_Name_2__c;
		}

		// this is required as per the field mapping design document (see references in class header). however it's unclear
		// why this has to be copied across from organisation on to a new billing account and how this is maintained ?
		newBillingAccount.ST_Priority_Customer__c = organisation?.Is_Strategic_Account_StarTrack__c;

		return newBillingAccount;
	}

	/**
	 * Returns updatable sub account request based on the billing account creation event.
	 * @param event platform event received from Camunda. Could be success or error.
	 *
	 * @return sub account request instance containing the updates from event passed in
	 */
	private APT_Sub_Account__c getUpdatableSubAccountRequest(BillingAccountCreationEvent__e event) {
		APT_Sub_Account__c updatableSubAccountRequest = new APT_Sub_Account__c(Id=event.Sub_Account_Request_Id__c);
		if (String.isNotBlank(event.Billing_Account_Number__c)) {
			updatableSubAccountRequest.Sub_Account_Number__c = event.Billing_Account_Number__c;
		}
		updatableSubAccountRequest.APT_Sub_Account_Request_Status__c = event.Status__c;
		updatableSubAccountRequest.Sub_Account_Request_Status_Description__c = event.Status_Description__c;
		return updatableSubAccountRequest;
	}

	/**
	 * Update any existing sub account requests still in 'Draft' and 'Error' status related to the deal support requests
	 * passed in, to populate leader billing account lookup (APT_Billing_Account__c), if the corresponding
	 * leader account is created during the processing of current batch of platform events.
	 *
	 * @param dealSupportRequests deal support requests where the leader account success event is received in the current batch of events.
	 * @param uow unit of work instance
	 */
	private void updateSubAccountRequestsOnDSRNotSubmittedForProvisioning(Map<Id, Deal_Support_Request__c> dealSupportRequests, ApplicationUnitOfWork uow) {

		// iterate through the deal support request records and populate charge account request id to deal support request id mapping.
		Map<Id, Id> chargeAccountRequestIdMapping = new Map<Id, Id>();
		for (Id dealSupportRequestId: dsrLeaderBillingAccountNumberMapping.keySet()) {
			Id chargeAccountRequestId = dealSupportRequests.get(dealSupportRequestId).APT_Contract__r?.Apttus_QPComply__RelatedProposalId__r?.APT_Credit_Assessment__r?.APT_Charge_Account__c;
			if (chargeAccountRequestId != null) {
				chargeAccountRequestIdMapping.put(chargeAccountRequestId, dealSupportRequestId);
			}
		}

		if (!chargeAccountRequestIdMapping.isEmpty()) {
			// retrieve all sub account requests in 'Draft' and 'Error' status linked to the charge account request ids collected above.
			Map<Id, APT_Sub_Account__c> subAccountRequests = ((SubAccountRequestsSelector) SubAccountRequestsSelector.newInstance().setFieldOverrides(new Set<SObjectField>{
					APT_Sub_Account__c.Id, APT_Sub_Account__c.APT_Sub_Account_Request_Status__c, APT_Sub_Account__c.APT_Charge_Account__c
			})).selectByChargeAcountRequestIdAndStatus(chargeAccountRequestIdMapping.keySet(), new Set<String>{'Draft', 'Error'});
			for (APT_Sub_Account__c subAccountRequest: subAccountRequests.values()) {
				Id dsrId = chargeAccountRequestIdMapping.get(subAccountRequest.APT_Charge_Account__c);
				String leaderAccountNumber = dsrLeaderBillingAccountNumberMapping.get(dsrId);
				APT_Sub_Account__c updatable = new APT_Sub_Account__c(Id=subAccountRequest.Id);
				uow.registerDirty(updatable, false, CreateSTBillingAccountEventHandlerModule.class.getName() + ':updateSubAccountRequestsNotSubmittedForProvisioning');
				// populate APT_Billing_Account__c lookup so the sub account request is linked to the leader billing account.
				// this is to allow retrying the sub account request in billing account flow.
				uow.registerRelationship(updatable, APT_Sub_Account__c.APT_Billing_Account__c, newBillingAccounts.get(leaderAccountNumber));
			}
		}
	}

	/**
	 * Returns updatable external onboarding request after applying relevant updates from the event passed in.
	 *
	 * @param event platform event received from Camunda. Could be success or error.
	 * @param updatable updatable instance with current state if updates from a prior event has already been applied
	 *				  to this external onboarding request. pass null for a external onboarding request not updated previously.
	 * @param oldRecord version of external onboarding request before applying updates from current batch of events.
	 *				  this is the version currently in database.
	 *
	 * @return external onboarding request record after applying updates from this event. Returns the same instance
	 *				  if non-null 'updatable' instance is supplied. returns a new instance otherwise.
	 */
	private BAMExternalOnboardingRequest__c getUpdatableExternalOnboardingRequest(BillingAccountCreationEvent__e event, BAMExternalOnboardingRequest__c updatable, BAMExternalOnboardingRequest__c oldRecord) {
		if (updatable == null) {
			updatable = new BAMExternalOnboardingRequest__c(Id=oldRecord.Id, Status__c=oldRecord.Status__c, Response_Payload__c=oldRecord.Response_Payload__c);
		}
		updatable.Response_Payload__c = (String.isNotBlank(updatable.Response_Payload__c) ? updatable.Response_Payload__c : '') + JSON.serialize(event, true);
		updatable.Response_Date__c = System.now();

		if (updatable.Status__c != 'Partial Success') {
			if ('Success'.equalsIgnoreCase(event.Status__c)) {
				updatable.Status__c = updatable.Status__c == 'Error' ? 'Partial Success' : 'Success';
			} else {
				updatable.Status__c = updatable.Status__c == 'Success' ? 'Partial Success' : 'Error';
			}
		}

		return updatable;
	}

	/**
	 * Returns updatable deal support request after applying relevant updates from the event passed in.
	 *
	 * @param event platform event received from Camunda. Could be success or error.
	 * @param isLeaderAccount indicates if this event is related to a leader billing account
	 * @param updatable updatable instance with current state if updates from a prior event has already been applied
	 *				  to this deal support request. pass null for a deal support request not updated previously.
	 *
	 * @return deal support request record after applying updates from this event. Returns the same instance
	 *		 if non-null 'updatable' instance is supplied. returns a new instance otherwise.
	 */
	private Deal_Support_Request__c getUpdatableDealSupportRequest(BillingAccountCreationEvent__e event, Boolean isLeaderAccount, Deal_Support_Request__c updatable) {
		if (isLeaderAccount || String.isNotBlank(event.Billing_Account_Number__c)) {
			if (updatable == null) {
				updatable = new Deal_Support_Request__c(Id=event.Request_Object_Id__c);
			}

			if (isLeaderAccount) {
				updatable.Integration_Status__c = event.Status__c;
				updatable.Integration_Status_Description__c = event.Status_Description__c;
				if (String.isNotBlank(event.Billing_Account_Number__c)) {
					updatable.Billing_Number__c = event.Billing_Account_Number__c;
				}
			} else {
				updatable.Sub_Accounts__c = (String.isNotBlank(updatable.Sub_Accounts__c) ? (updatable.Sub_Accounts__c + ';' + event.Billing_Account_Number__c) : event.Billing_Account_Number__c);
			}
		}
		return updatable;
	}

	/**
	 * Returns organisation role related to the customer organisation (account) record passed in updated to 'Customer' role.
	 *
	 * @param organisation customer organisation
	 *
	 * @return Organisation_Role__c instance with updated role type or null if no record needs to be updated.
	 */
	private Organisation_Role__c getUpdatableOrganisationRole(Account organisation) {
		if (organisation != null && !organisation.Organisation_Roles__r.isEmpty()) {
			return new Organisation_Role__c(Id=organisation.Organisation_Roles__r[0].Id, Role_Type__c='Customer');
		}
		return null;
	}

	/**
	 * Returns async worker param with relevant details to populate self lookups.
	 *
	 * @param event success event received from Camunda.
	 * @param newBillingAccount new billing account instance created as a result of the event
	 *
	 * @return async worker param, returns null if no post commit actions needed.
	 */
	private StarTrackBillingAccountPostCommitWorkerParam processSelfLookupsForNewBillingAccount(BillingAccountCreationEvent__e event, Billing_Account__c newBillingAccount) {
		StarTrackBillingAccountPostCommitWorkerParam postCommitWorkerParam = new StarTrackBillingAccountPostCommitWorkerParam();
		postCommitWorkerParam.billingAccountNumber = newBillingAccount.LEGACY_ID__c;

		if (String.isNotBlank(event.LeaderAccountNumber__c)) {
			populateBillingAccountSelfLookup(newBillingAccount, postCommitWorkerParam, Billing_Account__c.LeaderAccount__c, 'LeaderAccount__r', event.LeaderAccountNumber__c);
		}
		if (String.isNotBlank(event.Parent_Account_Number__c)) {
			populateBillingAccountSelfLookup(newBillingAccount, postCommitWorkerParam, Billing_Account__c.PAYER_ACCOUNT_ID__c,'PAYER_ACCOUNT_ID__r', event.Parent_Account_Number__c);
		}

		if (!postCommitWorkerParam.relatedBillingAccountNumbers.isEmpty()) {
			return postCommitWorkerParam;
		}

		return null;
	}

	/**
	 * Populate specified self lookup field on the billing account passed.
	 *
	 * Self lookup field is populated by reference if related billing account is already existing in database.
	 * If related billing account is also new, relationship details are populated on async worker param to be processed by async worker.
	 *
	 * @param newBillingAccount new billing account instance created.
	 * @param postCommitWorkerParam async worker parameters
	 * @param relatedToField lookup field to populate on billing account. used if passed into async worker param.
	 * @param relatedToRelationshipName relationship name. used if self lookup is set by reference.
	 * @param relatedBillingAccountNumber billing account number of related record
	 */
	private void populateBillingAccountSelfLookup(Billing_Account__c newBillingAccount, StarTrackBillingAccountPostCommitWorkerParam postCommitWorkerParam, SObjectField relatedToField, String relatedToRelationshipName, String relatedBillingAccountNumber) {
		if (newBillingAccounts.containsKey(relatedBillingAccountNumber)) {
			postCommitWorkerParam.relatedBillingAccountNumbers.put(String.valueOf(relatedToField), relatedBillingAccountNumber);
		} else {
			newBillingAccount.putSObject(relatedToRelationshipName, new Billing_Account__c(LEGACY_ID__c=relatedBillingAccountNumber));
		}
	}

	/**
	 * New DSR for surcharge setup and activation.
	 *
	 * @param event success event received from Camunda.
	 * @param organisation customer organisation
	 * @param subAccountRequest sub account request record referenced in the event. pass null if not available.
	 *
	 * @return new deal support request for surcharge setup and activation.
	 */
	private Deal_Support_Request__c newDSRForSurchargeSetupAndActivation(BillingAccountCreationEvent__e event, Account organisation, APT_Sub_Account__c subAccountRequest) {
		return new Deal_Support_Request__c(
				RecordTypeId = CUSTOMER_ONBOARDING_DSR_RECORDTYPEID, Organisation__c=organisation.Id, Requestor__c=subAccountRequest.OwnerId,
				Stage__c = 'Submitted', Status__c = 'Submitted', Sub_Accounts__c = event.Billing_Account_Number__c,
				Product__c = 'StarTrack', CustomerContact1__c = subAccountRequest.SubAccountContact__c,
				Work_Type__c = BILLING_ACCOUNT_CREATION_CONFIGURATION?.SurchargeSetupDSRWorkType__c,
				Support_Work_Type__c = BILLING_ACCOUNT_CREATION_CONFIGURATION?.SurchargeSetupDSRSupportWorkType__c,
				Description__c = System.Label.StarTrackSubAccountActivationDSRDescription, OwnerId= SURCHARGE_SETUP_DSR_OWNER_QUEUE.Id
		);
	}

	/**
	 * Select external onboarding request with all required fields populated via field overrides.
	 *
	 * @param externalOnboardingRequestIds Ids of the external onboarding requests to retrieve.
	 *
	 * @return external onboarding requests from database
	 */
	private Map<Id, BAMExternalOnboardingRequest__c> selectExternalOnboardingRequests(Set<Id> externalOnboardingRequestIds) {
		if (externalOnboardingRequestIds.isEmpty()) {
			return new Map<Id, BAMExternalOnboardingRequest__c>();
		}

		Set<SObjectField> fieldOverrides = new Set<SObjectField>{
				BAMExternalOnboardingRequest__c.Id, BAMExternalOnboardingRequest__c.Status__c, BAMExternalOnboardingRequest__c.Response_Payload__c,
				BAMExternalOnboardingRequest__c.OwnerId
		};
		return ((ExternalOnboardingRequestSelector)ExternalOnboardingRequestSelector.newInstance().setFieldOverrides(fieldOverrides)).selectById(externalOnboardingRequestIds);
	}

	/**
	 * Select deal support request with all required fields populated via field overrides.
	 *
	 * @param dealSupportRequestIds Ids of the deal support requests to retrieve.
	 *
	 * @return deal support requests from database
	 */
	private Map<Id, Deal_Support_Request__c> selectDealSupportRequests(Set<Id> dealSupportRequestIds) {
		if (dealSupportRequestIds.isEmpty()) {
			return new Map<Id, Deal_Support_Request__c>();
		}

		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				Deal_Support_Request__c.SObjectType => new Set<SObjectField> {
						Deal_Support_Request__c.Id, Deal_Support_Request__c.Billing_Number__c, Deal_Support_Request__c.Integration_Status__c,
						Deal_Support_Request__c.Integration_Status_Description__c, Deal_Support_Request__c.Sub_Accounts__c,
						Deal_Support_Request__c.APT_Contract__c, Deal_Support_Request__c.Organisation__c, Deal_Support_Request__c.Billing_Number__c,
						Deal_Support_Request__c.OwnerId, Deal_Support_Request__c.Opportunity__c, Deal_Support_Request__c.Name
				},
				APT_Credit_Assessment__c.SObjectType => new Set<SObjectField>{
						APT_Credit_Assessment__c.Id, APT_Credit_Assessment__c.APT_Charge_Account__c, APT_Credit_Assessment__c.StarTrack_Proposed_for_New_Account__c
				},
				Contact.SObjectType => new Set<SObjectField>{
						Contact.Id, Contact.Email, Contact.FirstName, Contact.LastName,
						Contact.Phone, Contact.MobilePhone, Contact.Fax
				},
				Opportunity.SObjectType => new Set<SObjectField>{
						Opportunity.Id, Opportunity.Primary_Pick_Up_Location__c
				}
		};
		return DealSupportRequestsSelector.newInstance(fieldOverrides).selectById(dealSupportRequestIds, new Set<Object>{
				DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT,
				DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT,
				DealSupportRequestsSelector.Options.WITH_OPPORTUNITY
		});
	}

	/**
	 * Select organisations with all required fields populated via field overrides.
	 *
	 * @param organisationIds Ids of the organisations to retrieve.
	 *
	 * @return organisations retrieved from database
	 */
	private Map<Id, Account> selectOrganisations(Set<Id> organisationIds) {
		if (organisationIds.isEmpty()) {
			return new Map<Id, Account>();
		}

		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				Account.SObjectType => new Set<SObjectField>{
						Account.Id, Account.Is_Strategic_Account_StarTrack__c, Account.ABN__c, Account.ACN__c, Account.BillingStreet,
						Account.BillingCity, Account.BillingPostalCode, Account.BillingState, Account.BillingCountry,
						Account.Primary_Business_Solutions_Contact__c, Account.Holding_Role_Reference__c, Account.Name
				},
				Organisation_Role__c.SObjectType => new Set<SObjectField>{
						Organisation_Role__c.Id, Organisation_Role__c.Role_Type__c
				},
				Holding_Role_Reference__c.SObjectType => new Set<SObjectField>{
						Holding_Role_Reference__c.Id, Holding_Role_Reference__c.Name
				}
		};
		return ((AccountsSelector)AccountsSelector.newInstance().setFieldOverrides(fieldOverrides)).selectById(organisationIds, new Set<Object>{
				AccountsSelector.Options.WITH_ORGANISATION_ROLES_PROSPECT_KNOWN,
				AccountsSelector.Options.WITH_HOLDINGROLE
		});
	}

	/**
	 * Select sub account requests with all required fields populated via field overrides.
	 *
	 * @param subAccountRequestIds Ids of the sub account requests to retrieve.
	 *
	 * @return sub account requests retrieved from database
	 */
	private Map<Id, APT_Sub_Account__c> selectSubAccountRequests(Set<Id> subAccountRequestIds) {
		if (subAccountRequestIds.isEmpty()) {
			return new Map<Id, APT_Sub_Account__c>();
		}

		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				APT_Sub_Account__c.SObjectType => new Set<SObjectField>{
						APT_Sub_Account__c.APT_Postal_Address_Street_Name__c, APT_Sub_Account__c.APT_Postal_Address_Suburb__c,
						APT_Sub_Account__c.APT_Postal_Address_Street_Postcode__c, APT_Sub_Account__c.APT_Postal_Address_State__c,
						APT_Sub_Account__c.APT_Postal_Address_Country_Code__c, APT_Sub_Account__c.APT_Sub_Account_Contact_Email_Address__c,
						APT_Sub_Account__c.APT_Account_Name_2__c, APT_Sub_Account__c.OwnerId, APT_Sub_Account__c.SubAccountContact__c,
						APT_Sub_Account__c.APT_Street_Address_Street_Number__c, APT_Sub_Account__c.APT_Street_Address_Street_Name__c,
						APT_Sub_Account__c.APT_Street_Address_Street_Type__c, APT_Sub_Account__c.APT_Street_Address_Suburb__c,
						APT_Sub_Account__c.APT_Street_Address_Street_Postcode__c, APT_Sub_Account__c.APT_Street_Address_State__c,
						APT_Sub_Account__c.APT_Street_Address_Country_Code__c, APT_Sub_Account__c.Name
				},
				Billing_Account__c.SObjectType => new Set<SObjectField>{
						Billing_Account__c.Id, Billing_Account__c.LEGACY_ID__c, Billing_Account__c.Name
				},
				Contact.SObjectType => new Set<SObjectField>{
						Contact.Phone, Contact.MobilePhone, Contact.Fax, Contact.FirstName, Contact.LastName, Contact.Email
				}
		};
		return ((SubAccountRequestsSelector)SubAccountRequestsSelector.newInstance().setFieldOverrides(fieldOverrides)).selectByIds(subAccountRequestIds, new Set<Object>{
				SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT, SubAccountRequestsSelector.Options.WITH_BILLING_ACCOUNT
		});
	}

	/**
	 * Select primary pickup locations for the opportunities related to the deal support requests passed in.
	 *
	 * @param dealSupportRequests deal support requests to retrieve pickup locations. Ensure the related opportunity record is
	 *							populated  on the deal support request supplied.
	 *
	 * @return pickup locations
	 */
	private Map<Id, Pick_Up_Location__c> selectPrimaryPickupLocations(List<Deal_Support_Request__c> dealSupportRequests) {

		Map<Id, Pick_Up_Location__c> results = new Map<Id, Pick_Up_Location__c>();

		Set<Id> pickupLocationIds = new Set<Id>();
		for (Deal_Support_Request__c dealSupportRequest: dealSupportRequests) {
			Id pickupLocationId = getOpportunityPickupLocationId(dealSupportRequest);
			if (pickupLocationId != null) {
				pickupLocationIds.add(pickupLocationId);
			}
		}

		if (!pickupLocationIds.isEmpty()) {
			results = ((PickUpLocationSelector)PickUpLocationSelector.newInstance().setFieldOverrides(new Set<SObjectField>{
					Pick_Up_Location__c.Id, Pick_Up_Location__c.Address__c, Pick_Up_Location__c.Suburb__c,
					Pick_Up_Location__c.Postcode__c, Pick_Up_Location__c.State__c
			})).selectById(pickupLocationIds);
		}

		return results;
	}

	/**
	 * Select billing accounts with all required fields populated via field overrides.
	 *
	 * @param billingAccountIds Ids of the organisations to retrieve.
	 *
	 * @return billing accounts retrieved from database
	 */
	private Map<Id, Billing_Account__c> selectBillingAccounts(Set<Id> billingAccountIds) {
		if (billingAccountIds.isEmpty()) {
			return new Map<Id, Billing_Account__c>();
		}

		return ((BillingAccountsSelector)BillingAccountsSelector.newInstance().setFieldOverrides(new Set<SObjectField>{
				Billing_Account__c.Id, Billing_Account__c.LEGACY_ID__c
		})).selectById(billingAccountIds);
	}

	/**
	 * Get a valid phone number from contact record.
	 *
	 * @param con contact record
	 *
	 * @return Contact.Phone if not blank, else Contact.MobilePhone
	 */
	private String getPhoneNumber(Contact con) {
		return (String.isNotBlank(con?.Phone) ? con.Phone : con?.MobilePhone);
	}

	/**
	 * Checks if the recordId supplied is an id of specified SObjectType
	 *
	 * @param recordId record id
	 * @param sObjectType Sobject Type
	 *
	 * @return true if specified id is a valid id for sobject type specified, false otherwise.
	 */
	private Boolean isRecordIdOfType(String recordId, SObjectType sObjectType) {
		try {
		 return (Id.valueOf(recordId).getSobjectType() == sObjectType);
		} catch (Exception ex) {
			// id is not a valid salesforce id. return false.
			return false;
		}
	}

	private Id getOpportunityPickupLocationId(Deal_Support_Request__c dealSupportRequest) {
		try {
			if (String.isNotBlank(dealSupportRequest?.Opportunity__r?.Primary_Pick_Up_Location__c)) {
				return Id.valueOf(dealSupportRequest?.Opportunity__r?.Primary_Pick_Up_Location__c);
			}
			return null;
		} catch (Exception e) {
			// opportunity is not linked to a valid pickup location. return null.
			return null;
		}
	}

	/**
	 * Send custom notifications to end users on billing account onboarding results.
	 *
	 * @param externalOnboardingResults external onboarding results
	 */
	private static void sendCustomNotifications(List<ExternalOnboardingResult> externalOnboardingResults) {
		Notifications notificationSender = Notifications.getInstance();
		for (ExternalOnboardingResult externalOnboardingResult: externalOnboardingResults) {
			if (externalOnboardingResult.requestObjectType == Deal_Support_Request__c.SObjectType) {
				// DSR flow
				notificationSender.add(newExternalOnboardingResultsNotificationForDSRFlow(externalOnboardingResult));
			} else if (externalOnboardingResult.requestObjectType == Billing_Account__c.SObjectType) {
				// Billing Account flow
				notificationSender.add(newExternalOnboardingResultsNotificationForBAFlow(externalOnboardingResult));
			}
		}
		notificationSender.send();
	}

	/**
	 * Create a custom notification instance from the external onboarding results of a request initiated via DSR flow.
	 *
	 * @param externalOnboardingResult onboarding results summarising billing account success / error events for the external onboarding request.
	 *
	 * @return custom notification configured with all necessary parameters.
	 */
	private static Notifications.CustomNotification newExternalOnboardingResultsNotificationForDSRFlow(ExternalOnboardingResult externalOnboardingResult) {
		String notificationTitle = '';
		String notificationBody = '';
		if (externalOnboardingResult.leaderBillingAccountProvisionResult != null) {
			if (externalOnboardingResult.subAccountProvisionResults.isEmpty()) {
				notificationTitle = externalOnboardingResult.leaderBillingAccountProvisionResult.isSuccess ? Label.StarTrackLeaderBillingAccountSuccessNotificationTitle : Label.StarTrackLeaderBillingAccountErrorNotificationTitle;
				notificationBody = (externalOnboardingResult.leaderBillingAccountProvisionResult.isSuccess ?
						String.format(Label.StarTrackLeaderBillingAccountSuccessNotification, new List<String>{externalOnboardingResult.leaderBillingAccountProvisionResult.newBillingAccountNumber, externalOnboardingResult.customerOrganisationName, externalOnboardingResult.requestObjectName}) :
						String.format(Label.StarTrackLeaderBillingAccountErrorNotification, new List<String>{externalOnboardingResult.customerOrganisationName, externalOnboardingResult.requestObjectName})
				);
			} else {
				// leader and follower/offspring
				if (externalOnboardingResult.failedSubAccountCount == 0) {
					// all successful (Refer scenario#4 in Custom Notification design in class header)
					notificationTitle = Label.StarTrackLeaderAndSubAccountsSuccessNotificationTitle;
					notificationBody = String.format(Label.StarTrackLeaderAndSubAccountsSuccessNotification, new List<String>{externalOnboardingResult.leaderBillingAccountProvisionResult.newBillingAccountNumber, externalOnboardingResult.getSuccessfulSubAccountNumberString(), externalOnboardingResult.customerOrganisationName, externalOnboardingResult.requestObjectName});
				} else if (externalOnboardingResult.successfulSubAccountCount == 0) {
					// all sub accounts failed (Refer scenario#3 and scenario#6 in Custom Notification design in class header)
					notificationTitle = (externalOnboardingResult.leaderBillingAccountProvisionResult.isSuccess ? Label.StarTrackLeaderSuccessAndSubAccountsErrorNotificationTitle : Label.StarTrackLeaderAndSubAccountsErrorNotificationTitle);
					notificationBody = (externalOnboardingResult.leaderBillingAccountProvisionResult.isSuccess ?
							String.format(Label.StarTrackLeaderSuccessAndSubAccountsErrorNotification, new List<String>{externalOnboardingResult.leaderBillingAccountProvisionResult.newBillingAccountNumber, externalOnboardingResult.getFailedSubAccountRequestNumbers(), externalOnboardingResult.requestObjectName}) :
							String.format(Label.StarTrackLeaderAndSubAccountsErrorNotification, new List<String>{externalOnboardingResult.customerOrganisationName, externalOnboardingResult.requestObjectName})
					);
				} else {
					// sub accounts partial success (Refer scenario#5 in Custom Notification design in class header)
					notificationTitle = Label.StarTrackLeaderSuccessAndSubAccountsPartialSuccessNotificationTitle;
					notificationBody = String.format(Label.StarTrackLeaderSuccessAndSubAccountsPartialSuccessNotification, new List<String>{externalOnboardingResult.leaderBillingAccountProvisionResult.newBillingAccountNumber, externalOnboardingResult.getSuccessfulSubAccountNumberString(), externalOnboardingResult.getFailedSubAccountRequestNumbers(), externalOnboardingResult.requestObjectName});
				}
			}
		} else {
			// very unlikely. only possible if leader platform event was processed in a previous batch by the platform event trigger.
			if (externalOnboardingResult.failedSubAccountCount == 0) {
				//all successful
				notificationTitle = Label.StarTrackSubAccountsSuccessNotificationTitle;
				notificationBody = String.format(Label.StarTrackLeaderUnknownSubAccountsSuccessNotification, new List<String>{externalOnboardingResult.getSuccessfulSubAccountNumberString(), externalOnboardingResult.customerOrganisationName, externalOnboardingResult.requestObjectName});
			} else if (externalOnboardingResult.successfulSubAccountCount == 0) {
				// all sub accounts failed
				notificationTitle = Label.StarTrackSubAccountsErrorNotificationTitle;
				notificationBody = String.format(Label.StarTrackLeaderUnknownSubAccountsErrorNotification, new List<String>{externalOnboardingResult.customerOrganisationName, externalOnboardingResult.getFailedSubAccountRequestNumbers(), externalOnboardingResult.requestObjectName});
			} else {
				// sub accounts partial success
				notificationTitle = Label.StarTrackSubAccountsPartialSuccessNotificationTitle;
				notificationBody = String.format(Label.StarTrackLeaderUnknownSubAccountsPartialSuccessNotification, new List<String>{externalOnboardingResult.getSuccessfulSubAccountNumberString(), externalOnboardingResult.getFailedSubAccountRequestNumbers(), externalOnboardingResult.requestObjectName});
			}
		}

		return Notifications.create()
					.setNotificationTypeId(Notifications.DEFAULT_CUSTOM_NOTIFICATION_TYPE_ID)
					.setSenderId(UserInfo.getUserId())
					.setTitle(notificationTitle)
					.setBody(notificationBody)
					.setTargetId(externalOnboardingResult.requestObjectId)
					.setRecipientIds(new Set<Id>{externalOnboardingResult.externalOnboardingRequest.OwnerId});
	}

	/**
	 * Create a custom notification instance from the external onboarding results of a request initiated via billing account flow.
	 *
	 * @param externalOnboardingResult onboarding results summarising billing account success / error events for the external onboarding request.
	 *
	 * @return custom notification configured with all necessary parameters.
	 */
	private static Notifications.CustomNotification newExternalOnboardingResultsNotificationForBAFlow(ExternalOnboardingResult externalOnboardingResult) {
		String notificationTitle = '';
		String notificationBody = '';
		if (externalOnboardingResult.failedSubAccountCount == 0) {
			//all successful (Refer scenario#7 in Custom Notification design in class header)
			notificationTitle = Label.StarTrackSubAccountsSuccessNotificationTitle;
			notificationBody = String.format(Label.StarTrackSubAccountsSuccessNotification, new List<String>{externalOnboardingResult.requestObjectName, externalOnboardingResult.getSuccessfulSubAccountNumberString()});
		} else if (externalOnboardingResult.successfulSubAccountCount == 0) {
			// all failed (Refer scenario#8 in Custom Notification design in class header)
			notificationTitle = Label.StarTrackSubAccountsErrorNotificationTitle;
			notificationBody = String.format(Label.StarTrackSubAccountsErrorNotification, new List<String>{externalOnboardingResult.requestObjectName, externalOnboardingResult.getFailedSubAccountRequestNumbers()});
		} else {
			// partial (Refer scenario#9 in Custom Notification design in class header)
			notificationTitle = Label.StarTrackSubAccountsPartialSuccessNotificationTitle;
			notificationBody = String.format(Label.StarTrackSubAccountsPartialSuccessNotification, new List<String>{externalOnboardingResult.requestObjectName, externalOnboardingResult.getSuccessfulSubAccountNumberString(), externalOnboardingResult.getFailedSubAccountRequestNumbers()});
		}
		return Notifications.create()
				.setNotificationTypeId(Notifications.DEFAULT_CUSTOM_NOTIFICATION_TYPE_ID)
				.setSenderId(UserInfo.getUserId())
				.setTitle(notificationTitle)
				.setBody(notificationBody)
				.setTargetId(externalOnboardingResult.requestObjectId)
				.setRecipientIds(new Set<Id>{externalOnboardingResult.externalOnboardingRequest.OwnerId});
	}

	/**
	 * Async worker for handling post commit actions required on newly inserted star track billing accounts.
	 * Caters for below scenarios:
	 *  - populate self lookup fields on new billing accounts
	 */
	public inherited sharing class CreateStarTrackBillingAccountPostCommitAsyncWorker extends ApplicationUnitOfWork.AsyncWorker {

		private List<StarTrackBillingAccountPostCommitWorkerParam> params = new List<StarTrackBillingAccountPostCommitWorkerParam>();

		public override void execute(ApplicationUnitOfWork uow) {

			// query all billing accounts referenced in params.
			Map<String, Billing_Account__c> billingAccounts = selectBillingAccounts(this.params);

			// list of excluded record external ids as either the record or the related record does not exist
			// this could happen in the unlikely scenario where a billing account failed to insert.
			Map<String, Map<String, String>> excludedRelationshipsLog = new Map<String, Map<String, String>>();

			for (StarTrackBillingAccountPostCommitWorkerParam param: params) {
				if (String.isNotBlank(param.billingAccountNumber)) {
					Billing_Account__c billingAccount = billingAccounts.get(param.billingAccountNumber);
					if (billingAccount != null) {
						Billing_Account__c updatable = new Billing_Account__c();
						for (String relatedToField: param.relatedBillingAccountNumbers.keySet()) {
							String relatedBillingAccountNumber = param.relatedBillingAccountNumbers.get(relatedToField);
							Billing_Account__c relatedBillingAccount = billingAccounts.get(relatedBillingAccountNumber);
							if (relatedBillingAccount != null) {
								// related billing account exists. populate relevant lookup field in updatable instance.
								updatable.put(Billing_Account__c.Id, billingAccount.Id);
								updatable.put(relatedToField, relatedBillingAccount.Id);
							} else {
								// related billing account does not exist. add to excluded relationships log.
								addToExcludedRelationshipsLog(excludedRelationshipsLog, param.billingAccountNumber, new Map<String, String>{relatedToField => relatedBillingAccountNumber});
							}
						}
						if (updatable.Id != null) {
							// we have updates to be registered with uow. we only populate id when there are valid changes to be made.
							uow.registerDirty(updatable, false, CreateStarTrackBillingAccountPostCommitAsyncWorker.class.getName());
						}
					} else {
						// billing account record with the matching billing account number does not exist. add to excluded relationships log.
						addToExcludedRelationshipsLog(excludedRelationshipsLog, param.billingAccountNumber, param.relatedBillingAccountNumbers);
					}
				}
			}

			if (!excludedRelationshipsLog.isEmpty()) {
				logExcludedRelationships(excludedRelationshipsLog, billingAccounts);
			}
		}

		public override Type getClassType() {
			return CreateStarTrackBillingAccountPostCommitAsyncWorker.class;
		}

		public override void deserialiseParams(String serialisedParams) {
			if (!String.isEmpty(serialisedParams)) {
				try {
					this.params = (List<StarTrackBillingAccountPostCommitWorkerParam>) JSON.deserialize(serialisedParams, List<StarTrackBillingAccountPostCommitWorkerParam>.class);
				} catch (Exception e) {
					ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales', CreateStarTrackBillingAccountPostCommitAsyncWorker.class.getName(),
							'deserialiseParams', String.valueOf(BillingAccountCreationEvent__e.SObjectType), ApplicationLogger.LoggingLevel.ERROR);
				}
			}
		}

		public override SObjectType getSObjectTypeGroup() {
			return Billing_Account__c.SObjectType;
		}

		private Map<String, Billing_Account__c> selectBillingAccounts(List<StarTrackBillingAccountPostCommitWorkerParam> params) {

			Map<String, Billing_Account__c> results = new Map<String, Billing_Account__c>();

			Set<String> billingAccountNumbers = new Set<String>();
			for (StarTrackBillingAccountPostCommitWorkerParam param: params) {
				billingAccountNumbers.add(param.billingAccountNumber);
				billingAccountNumbers.addAll(param.relatedBillingAccountNumbers.values());
			}

			if (!billingAccountNumbers.isEmpty()) {
				Map<Id, Billing_Account__c> billingAccounts = ((BillingAccountsSelector) BillingAccountsSelector.newInstance().setFieldOverrides(new Set<SObjectField>{
						Billing_Account__c.Id, Billing_Account__c.LEGACY_ID__c, Billing_Account__c.Customer_Name__c
				})).selectByAccountNumber(billingAccountNumbers);

				for (Billing_Account__c billingAccount: billingAccounts.values()) {
					results.put(billingAccount.LEGACY_ID__c, billingAccount);
				}
			}

			return results;
		}

		private void addToExcludedRelationshipsLog(Map<String, Map<String, String>> excludedRelationships, String billingAccountNumber, Map<String, String> billingAccountExcludedRelationships) {
			if (!excludedRelationships.containsKey(billingAccountNumber)) {
				excludedRelationships.put(billingAccountNumber, new Map<String, String>());
			}
			excludedRelationships.get(billingAccountNumber).putAll(billingAccountExcludedRelationships);
		}

		/**
		 * Generate log entries from the excluded records collected while processing.
		 *
		 * @param excludedRelationships Excluded records to generate log entries.
		 * @param billingAccounts Billing accounts found for the billing account numbers supplied.
		 */
		private void logExcludedRelationships(Map<String, Map<String, String>> excludedRelationships, Map<String, Billing_Account__c> billingAccounts) {

			List<String> messages = new List<String>();
			List<String> additionalInfo = new List<String>();

			for (String billingAccountNumber: excludedRelationships.keySet()) {
				if (!billingAccounts.containsKey(billingAccountNumber)) {
					messages.add('Billing account [' + billingAccountNumber + '] does not exist. Ignoring linking with related billing accounts.');
				} else {
					messages.add('Related billing account(s) does not exist for billing account [' + billingAccountNumber + ']. Ignoring linking with related billing accounts');
				}
				additionalInfo.add('Ignored relationships : ' + excludedRelationships.get(billingAccountNumber));
			}

			ApplicationLogger.getInstance().logMessage(messages, additionalInfo, 'Sales', CreateStarTrackBillingAccountPostCommitAsyncWorker.class.getName(), 'execute', '', ApplicationLogger.LoggingLevel.ERROR);
		}

	}

	/**
	 * Async worker params to be passed into Async worker handling post commit actions on newly inserted star track billing accounts.
	 */
	public class StarTrackBillingAccountPostCommitWorkerParam {
		// billing account number (Billing_Account__c.LEGACY_ID__c)
		public String billingAccountNumber;
		// related billing account numbers to populate self lookups. key - lookup field API name, value - related billing account number.
		public Map<String, String> relatedBillingAccountNumbers = new Map<String, String>();
	}

	/**
	 * Summary of billing account provisioning results per external onboarding request sent from Salesforce. May contain
	 * leader account results and/or sub account results depending on the contents of the onboarding request generated
	 * in Salesforce.
	 */
	private class ExternalOnboardingResult {
		// external onboarding request instance
		private BAMExternalOnboardingRequest__c externalOnboardingRequest;
		// record from which the onboarding request was initiated. could be either a deal support request (DSR flow) or a billing account (BA flow)
		private Id requestObjectId;
		// request record name known to business users
		private String requestObjectName;
		// SObjectType of the request object. Could be either DEal_Support_Request__c or Billing_Account__c
		private SObjectType requestObjectType;
		// customer organisation (i.e. Account) linked to the request object.
		private String customerOrganisationName;
		// results of leader billing account provision results. Only populated if leader accounts are included in external onboarding request.
		private BillingAccountProvisionResult leaderBillingAccountProvisionResult;
		// results of sub account provision results. Only populated if sub accounts are included in external onboarding request.
		private List<BillingAccountProvisionResult> subAccountProvisionResults = new List<BillingAccountProvisionResult>();
		// number of successfully provisioned sub accounts
		private Integer successfulSubAccountCount;
		// number of failed sub account requests
		private Integer failedSubAccountCount;

		/**
		 * Creates a new instance of onboarding results
		 *
		 * @param externalOnboardingRequest Onboarding request instance (BAMExternalOnboardingRequest__c)
		 * @param requestObjectId Record from which the onboarding request was initiated. could be either a deal support request (DSR flow) or a billing account (BA flow)
		 * @param requestObjectName Request record name known to business users
		 * @param customerOrganisationName customer organisation (i.e. Account) linked to the request object.
		 */
		private ExternalOnboardingResult(BAMExternalOnboardingRequest__c externalOnboardingRequest, Id requestObjectId, String requestObjectName, String customerOrganisationName) {
			this.externalOnboardingRequest = externalOnboardingRequest;
			this.requestObjectId = requestObjectId;
			this.requestObjectType = requestObjectId.getSobjectType();
			this.requestObjectName = requestObjectName;
			this.customerOrganisationName = customerOrganisationName;
			this.successfulSubAccountCount = 0;
			this.failedSubAccountCount = 0;
		}

		/**
		 * Record provision result of a billing account requested in the external onboarding request.
		 *
		 * @param accountRequest Account request record. Could be an instance of either APT_Charge_Account__c or APT_Sub_Account__c.
		 * @param newBillingAccountNumber newly provisioned billing account number from external system. pass null if billing account was not provisioned.
		 */
		private void addBillingAccountProvisionResult(SObject accountRequest, String newBillingAccountNumber) {
			BillingAccountProvisionResult result = new BillingAccountProvisionResult(accountRequest, newBillingAccountNumber);
			if (accountRequest?.getSObjectType() == APT_Charge_Account__c.SObjectType) {
				this.leaderBillingAccountProvisionResult = result;
			} else {
				this.subAccountProvisionResults.add(result);
				if (result.isSuccess) {
					++successfulSubAccountCount;
				} else {
					++failedSubAccountCount;
				}
			}
		}

		/**
		 * Get failed sub account request numbers in a comma separated list.
		 *
		 * @return sub account request numbers
		 */
		private String getFailedSubAccountRequestNumbers() {
			String result = '';
			for (BillingAccountProvisionResult provisionResult: this.subAccountProvisionResults) {
				if (!provisionResult.isSuccess) {
					result += (provisionResult.accountRequest.get('Name') + ', ');
				}
			}
			return result.removeEnd(', ');
		}

		/**
		 * Get successfully provisioned new billing account numbers in a comma separated list.
		 *
		 * @return newly provisioned billing account numbers
		 */
		private String getSuccessfulSubAccountNumberString() {
			String result = '';
			for (BillingAccountProvisionResult provisionResult: this.subAccountProvisionResults) {
				if (provisionResult.isSuccess) {
					result += (provisionResult.newBillingAccountNumber + ', ');
				}
			}
			return result.removeEnd(', ');
		}

	}

	/**
	 * Provision result of a single billing account request. Note that this could be a leader account or a sub account.
	 */
	private class BillingAccountProvisionResult {
		// account request record. Could be an instance of either APT_Charge_Account__c or APT_Sub_Account__c.
		private SObject accountRequest;
		// newly provisioned billing account number from external system.
		private String newBillingAccountNumber;
		// indicates if billing account was provisioned successfully.
		private Boolean isSuccess;

		/**
		 * Creates a new instance of billing account provision result.
		 * @param accountRequest account request record. Could be an instance of either APT_Charge_Account__c or APT_Sub_Account__c.
		 * @param newBillingAccountNumber newly provisioned billing account number from external system. pass null if billing account was not provisioned.
		 */
		private BillingAccountProvisionResult(SObject accountRequest, String newBillingAccountNumber) {
			this.accountRequest = accountRequest;
			this.newBillingAccountNumber = newBillingAccountNumber;
			this.isSuccess = String.isNotBlank(newBillingAccountNumber);
		}
	}
}