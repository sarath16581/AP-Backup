/**
 * @description Controller class responsible for generating and submitting requests to provision new StarTrack billing
 *			  accounts to external service (via Camunda to TEAM).
 *			  Supports provisioning new billing accounts in DSR flow (initiated from a DSR record) as well as billing
 *			  account flow (initiated from the leader billing account already provisioned). DSR flow provisions a single
 *			  leader account and optionally a list of sub accounts. Billing Account flow only support provisioning
 *			  new sub accounts.
 *
 *			  Design Documentation
 *			  - Request data mapping [https://australiapost.jira.com/wiki/spaces/STP/pages/2814837533/Design+OB010+Request+JSON+Mapping+Salesforce+Camunda+-+TEAM]
 *			  - Acknowledgement (Continuation Callback) [https://australiapost.jira.com/wiki/spaces/STP/pages/2825295528/Design+Acknowledgment]
 *
 * @author Ranjeewa Silva
 * @date 2023-11-02
 * @changelog
 * 2023-11-02 - Ranjeewa Silva - Created
 */
public with sharing class ProvisionSTBillingAccountsController {

	// role types that needs to be assigned to the parent organisation to allow provisioning new leader billing accounts
	@TestVisible private static final Set<String> VALID_ORGANISATION_ROLE_TYPES = new Set<String>{'Customer', 'Prospect', 'Known'};
	// valid status the related credit assessment must be in to initiate provisioning new leader billing accounts.
	@TestVisible private static final Set<String> VALID_CREDIT_ASSESSMENT_STATUS = new Set<String>{'Approved', 'Auto-Approved'};

	// account type on a sub account request whose invoice is to be paid by the leader billing account.
	@TestVisible private static final String INVOICE_PAID_BY_LEADER_ACCOUNT_TYPE = 'Offspring';
	// account type on a sub account request whose invoice is to be paid by another sub account under the leader billing account.
	@TestVisible private static final String INVOICE_PAID_BY_OTHER_ACCOUNT_TYPE = 'Offspring Follower';

	// process type identifier to be included in request payload for requests initiated via DSR flow.
	@TestVisible private static final String DSR_FLOW_PROCESS_TYPE = 'Assisted Onboarding - New TEAM Leader Account with Follower/Offspring Account';
	// process type identifier to be included in request payload for requests initiated via Billing Accounts flow.
	@TestVisible private static final String BILLING_ACCOUNT_FLOW_PROCESS_TYPE = 'Assisted Onboarding - New TEAM Follower/Offspring Account';

	// external service interface requires a secondary contact to be specified. below static values are to be supplied
	// as first name, last name and job title.
	@TestVisible private static final String NEW_ACCOUNT_SECONDARY_CONTACT_FIRSTNAME = 'Accounts';
	@TestVisible private static final String NEW_ACCOUNT_SECONDARY_CONTACT_LASTNAME = 'Payable';
	@TestVisible private static final String NEW_ACCOUNT_SECONDARY_CONTACT_JOB_TITLE = 'Accounts Payable';

	// hold the value of the Continuation.state attribute. intended to be used in unit test purpose only.
	@TestVisible private static Object continuationState;

	/**
	 * Check pre-conditions for provisioning new billing accounts via DSR flow. All pre-conditions must be satisfied
	 * prior to submitting request to external service.
	 *
	 * @param dealSupportRequestId Id of the deal support request from where the request was initiated
	 *
	 * @return results of the pre-condition check
	 */
	@AuraEnabled(Cacheable=false)
	public static PreConditionsCheckResult checkBillingAccountProvisioningPreconditions(Id dealSupportRequestId) {
		try {
			// query deal support request including related records
			Deal_Support_Request__c dealSupportRequest = selectDealSupportRequest(dealSupportRequestId);

			// generate request payload from the deal support request and related records
			BillingAccountWrapperForTeams request = generateNewBillingAccountsProvisionRequestPayload(dealSupportRequest);

			// check pre-conditions and return results
			return checkProvisioningPreConditions(request, dealSupportRequest);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Generate provisioning request that can be submitted to external service.
	 *
	 * @param dealSupportRequestId Id of the deal support request from where the request was initiated
	 *
	 * @return generated request and the external onboarding request id
	 */
	@AuraEnabled(Cacheable=false)
	public static BillingAccountProvisioningDetails generateBillingAccountsProvisioningRequest(Id dealSupportRequestId) {

		// check pre-conditions to ensure they are all satisfied.
		PreConditionsCheckResult preConditionsCheckResult = checkBillingAccountProvisioningPreconditions(dealSupportRequestId);
		if (preConditionsCheckResult.status != PreConditionsCheckStatus.READY_FOR_SUBMISSION.name()) {
			// pre-conditions are not satisfied. throw an exception to LWC layer.
			// LWC layer should ensure all pre-conditions are satisfied before attempting to generate request.
			String msg = 'Cannot submit request with validation errors. Please resolve validation errors and try again.';
			throw new AuraHandledException(msg);
		}

		try {
			// extract request payload returned in pre condition check results
			BillingAccountWrapperForTeams provisioningRequest = (BillingAccountWrapperForTeams)preConditionsCheckResult.requestPayload;
			// create new external onboarding request and return the request payload including the external onboarding request id.
			// note that the request payload gets updated in this step to set newly created external onboarding request id
			// as the transaction id.
			return createNewExternalOnboardingRequest(provisioningRequest);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Generate sub accounts provisioning request that can be submitted to external service.
	 *
	 * @param leaderBillingAccountId leader billing account Id (already existing in Salesforce)
	 * @param subAccountRequestIds list of sub account request Ids to be included in the provisioning request to external system.
	 *
	 * @return generated request and the external onboarding request id
	 */
	@AuraEnabled(Cacheable=false)
	public static BillingAccountProvisioningDetails generateSubAccountsProvisioningRequest(Id leaderBillingAccountId, List<Id> subAccountRequestIds) {
		try {
			// generate request payload. note that pre-condition check is not necessary as this is to provision new sub accounts
			// on to an existing leader billing account.
			BillingAccountWrapperForTeams provisioningRequest = generateNewSubAccountsProvisionRequestPayload(leaderBillingAccountId, subAccountRequestIds);
			// create new external onboarding request and return the request payload including the external onboarding request id.
			// note that the request payload gets updated in this step to set newly created external onboarding request id
			// as the transaction id.
			return createNewExternalOnboardingRequest(provisioningRequest);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Submit provisioning request to external service asynchronously.
	 *
	 * @param request provisioning request to submit
	 * @param externalOnboardingRequestId external onboarding request id capturing status of the provisioning request and response from external service.
	 *
	 * @return continuation instance.
	 */
	@AuraEnabled(Continuation=true Cacheable=false)
	public static Object submitProvisioningRequest(BillingAccountWrapperForTeams request, Id externalOnboardingRequestId) {
		Continuation con = BillingAccountService.getInstance().getContinuation(JSON.serialize(request, true), externalOnboardingRequestId, 'Salesforce');
		// populate context data to pass on to continuation callback handler via state
		AsyncExecutionContext context = new AsyncExecutionContext();
		context.requestObjId = request.requestObjId;
		context.chargeAccountRequestId = request.team?.organisations?.leaderAccountRequestId;
		context.onboardingRequestId = externalOnboardingRequestId;
		context.processType = request.processType;
		context.subAccountRequestIds = request.team.getSubAccountRequestIds();
		con.state = context;

		// set continuation state on class level attribute so that we can verify this in unit tests
		ProvisionSTBillingAccountsController.continuationState = context;

		con.continuationMethod = 'processBillingAccountProvisioningCallback';
		return con;
	}

	/**
	 * Continuation callback for asynchronous callout to provision billing accounts.
	 *
	 * @param labels Labels attached to requests included in this continuation
	 * @param state Continuation state information set at the time of request
	 *
	 * @return parsed response from external service
	 */
	@AuraEnabled(Cacheable=false)
	public static BillingAccountService.Response processBillingAccountProvisioningCallback(List<String> labels, Object state) {
		AsyncExecutionContext context = (AsyncExecutionContext) state;
		HttpResponse httpResponse = Continuation.getResponse(labels[0]);
		BillingAccountService.Response response = BillingAccountService.getInstance().parseResponse(httpResponse);
		// update relevant records with the results of the provisioning api call.
		updateProvisioningStatus(response, context);
		return response;
	}

	/**
	 * Update records in current context with the status of provisioning api call (i.e. success/fail).
	 *
	 * @param response Parsed response from service
	 * @param context Execution context details
	 */
	private static void updateProvisioningStatus(BillingAccountService.Response response, AsyncExecutionContext context) {
		List<SObject> updatable = new List<SObject>();

		// update external onboarding request record with response payload, status and any errors returned
		BAMExternalOnboardingRequest__c externalOnboardingRequest = new BAMExternalOnboardingRequest__c(Id=context.onboardingRequestId);
		externalOnboardingRequest.Response_Payload__c = (String.isNotBlank(response.responseBody) ? response.responseBody : response.getErrorMessage());
		externalOnboardingRequest.Status__c = (response.isSuccess ? 'Pending' : 'Error');
		if (!response.isSuccess) {
			// set Error__c field to the first 255 characters of the error message
			externalOnboardingRequest.Error__c = response.getErrorMessage().left(255);
		}
		updatable.add(externalOnboardingRequest);

		// if invoked in DSR flow, update deal support request and the charge account request records
		if (context.processType == DSR_FLOW_PROCESS_TYPE) {
			Deal_Support_Request__c dealSupportRequest = new Deal_Support_Request__c(Id=context.requestObjId);
			dealSupportRequest.Integration_Transaction_Id__c = context.onboardingRequestId;
			dealSupportRequest.Integration_Status__c= (response.isSuccess ? 'Requested' : 'Error');
			if (!response.isSuccess) {
				dealSupportRequest.Integration_Status_Description__c = response.getErrorMessage();
			}
			updatable.add(dealSupportRequest);

			if (context.chargeAccountRequestId != null) {
				APT_Charge_Account__c chargeAccountRequest = new APT_Charge_Account__c(Id=context.chargeAccountRequestId);
				chargeAccountRequest.Status__c = (response.isSuccess ? 'New' : 'Error');
				updatable.add(chargeAccountRequest);
			}
		}

		// if request included any sub account provisioning requests, update those records with provisioning status
		if (context.subAccountRequestIds != null && !context.subAccountRequestIds.isEmpty()) {
			for (Id subAccountRequestId: context.subAccountRequestIds) {
				APT_Sub_Account__c subAccountRequest = new APT_Sub_Account__c(Id=subAccountRequestId);
				subAccountRequest.Transaction_Id__c = context.onboardingRequestId;
				subAccountRequest.APT_Sub_Account_Request_Status__c = (response.isSuccess ? 'Submitted' : 'Error');
				updatable.add(subAccountRequest);
			}
		}

		// update all sobject records.
		List<Database.SaveResult> saveResults = ApplicationDatabase.getInstance().dmlUpdate(updatable, false);
		// inspect save results and log any failures in exception logs.
		ApplicationLogger.getInstance().logFailedDatabaseResults(saveResults, 'Sales', ProvisionSTBillingAccountsController.class.getName(), 'updateProvisioningStatus', null, ApplicationLogger.LoggingLevel.ERROR);
	}

	/**
	 * Generate new billing accounts provisioning request from the deal support request passed in.
	 *
	 * @param dealSupportRequest deal support request to generate the provisioning request
	 *
	 * @return provisioning request
	 */
	private static BillingAccountWrapperForTeams generateNewBillingAccountsProvisionRequestPayload(Deal_Support_Request__c dealSupportRequest) {

		BillingAccountWrapperForTeams request = new BillingAccountWrapperForTeams(dealSupportRequest.Id, DSR_FLOW_PROCESS_TYPE);

		if (dealSupportRequest.APT_Contract__c != null && dealSupportRequest.Organisation__c != null) {
			request.team.organisations = generateOrganisationsRequestPayload(dealSupportRequest);
			request.team.creditDetails = generateCreditDetailsRequestPayload(dealSupportRequest);
			request.team.service = generateServiceCodesRequestPayload(dealSupportRequest.APT_Contract__r);
			Id chargeAccountRequestId = dealSupportRequest.APT_Contract__r.Apttus_QPComply__RelatedProposalId__r?.APT_Credit_Assessment__r?.APT_Charge_Account__c;
			request.team.followerOffspringList = generateFollowerOffspringRequestPayload(chargeAccountRequestId);
			request.orgRecordId = dealSupportRequest.Organisation__c;
		}

		return request;
	}

	/**
	 * Generate new sub accounts provisioning request for the list of sub account requests supplied. New sub accounts to
	 * be provisioned with the leader billing account specified.
	 *
	 * @param leaderBillingAccountId Existing leader billing account Id
	 * @param subAccountRequestIds list of sub account request record ids to be included in provisioning request.
	 *
	 * @return provisioning request
	 */
	private static BillingAccountWrapperForTeams generateNewSubAccountsProvisionRequestPayload(Id leaderBillingAccountId, List<Id> subAccountRequestIds) {

		BillingAccountWrapperForTeams request = new BillingAccountWrapperForTeams(leaderBillingAccountId, BILLING_ACCOUNT_FLOW_PROCESS_TYPE);

		// query sub account requests with related record data
		List<APT_Sub_Account__c> subAccountRequests = selectSubAccountRequests(new Set<Id>(subAccountRequestIds));
		if (!subAccountRequests.isEmpty()) {
			request.team.organisations = new BillingAccountWrapperForTeams.Organisations(subAccountRequests[0].APT_Billing_Account__r?.ABN__c, subAccountRequests[0].APT_Billing_Account__r?.ACN__c, null);
			request.team.organisations.billingAccountNo = subAccountRequests[0].APT_Billing_Account__r?.LEGACY_ID__c;
			request.team.followerOffspringList = generateFollowerOffspringPayload(subAccountRequests);
			request.orgRecordId = subAccountRequests[0].APT_Billing_Account__r?.Organisation__c;
		}

		return request;
	}

	/**
	 * Generate 'team.organisations' portion of request payload
	 *
	 * @param dealSupportRequest deal support request to source data from
	 *
	 * @return generated 'team.organisations' node of request payload
	 */
	private static BillingAccountWrapperForTeams.Organisations generateOrganisationsRequestPayload(Deal_Support_Request__c dealSupportRequest) {
		Account organisation = dealSupportRequest.Organisation__r;
		Contact primaryContact = dealSupportRequest.APT_Contract__r?.Apttus__Primary_Contact__r;
		Id chargeAccountRequestId = dealSupportRequest.APT_Contract__r.Apttus_QPComply__RelatedProposalId__r?.APT_Credit_Assessment__r?.APT_Charge_Account__c;
		Pick_Up_Location__c pickupLocation = selectPickupLocation(dealSupportRequest.Opportunity__r);
		BillingAccountWrapperForTeams.Organisations organisations = new BillingAccountWrapperForTeams.Organisations(organisation.ABN__c, organisation.ACN__c, organisation.Name);
		if (chargeAccountRequestId != null) {
			organisations.leaderAccountRequestId = chargeAccountRequestId;
		}

		// setup primary contact Details
		if (primaryContact != null) {
			organisations.primaryContact = new BillingAccountWrapperForTeams.Contact(primaryContact);
			organisations.secondaryContact = new BillingAccountWrapperForTeams.Contact(primaryContact);
			organisations.secondaryContact.firstName = NEW_ACCOUNT_SECONDARY_CONTACT_FIRSTNAME;
			organisations.secondaryContact.lastName = NEW_ACCOUNT_SECONDARY_CONTACT_LASTNAME;
			organisations.secondaryContact.jobTitle = NEW_ACCOUNT_SECONDARY_CONTACT_JOB_TITLE;

			organisations.phone = (primaryContact.Phone != null ? primaryContact.Phone : primaryContact.MobilePhone);
		}

		// mailing address
		if (pickupLocation != null) {
			organisations.mailingAddress = new BillingAccountWrapperForTeams.Address(pickupLocation.Address__c, pickupLocation.Suburb__c, pickupLocation.Postcode__c, true);
		}

		// billing address
		organisations.billingAddress = new BillingAccountWrapperForTeams.Address(organisation.BillingStreet, organisation.BillingCity, organisation.BillingPostalCode, true);

		return organisations;
	}

	/**
	 * Generate 'team.creditDetails' portion of request payload
	 *
	 * @param dealSupportRequest deal support request to source data from
	 *
	 * @return generated 'team.creditDetails' node of request payload
	 */
	private static BillingAccountWrapperForTeams.CreditDetails generateCreditDetailsRequestPayload(Deal_Support_Request__c dealSupportRequest) {
		BillingAccountWrapperForTeams.CreditDetails creditDetails = new BillingAccountWrapperForTeams.CreditDetails();

		Apttus__APTS_Agreement__c contract = dealSupportRequest.APT_Contract__r;

		creditDetails.creditAssessNo = contract.Apttus_QPComply__RelatedProposalId__r?.APT_Credit_Assessment__r?.Name ;
		creditDetails.creditLimit = Integer.valueOf(contract.Apttus_QPComply__RelatedProposalId__r?.APT_Credit_Assessment__r?.StarTrack_Proposed_for_New_Account__c);
		creditDetails.estimatedMonthlyRevenue =Integer.valueOf(contract.Apttus_QPComply__RelatedProposalId__r?.APT_Minimum_Monthly_Spend__c);

		if ('Open Ended'.equalsIgnoreCase(contract.Term__c)) {
			Date today = Date.today();
			// TODO Make these configurable '08-01' and '11-01' ??
			Date cutoffDate = Date.newInstance(today.year(), 08, 01);
			creditDetails.nextRevenueDueDate = Date.newInstance((today <= cutoffDate ? today.year() : today.year()+1), 11, 01);
		} else if ('Fixed Term'.equalsIgnoreCase(contract.Term__c)) {
			creditDetails.nextRevenueDueDate = contract.Apttus__Contract_End_Date__c;
		}

		creditDetails.authoriser = dealSupportRequest.Name;

		// TODO credit officer mapping is captured in a separate user story. defaulting for now.
		creditDetails.creditOfficer = 'P11';
		return creditDetails;
	}

	/**
	 * Generate 'team.service' portion of request payload
	 *
	 * @param contract apttus contract to source data from
	 *
	 * @return generated 'team.service' node of request payload
	 */
	private static List<String> generateServiceCodesRequestPayload(Apttus__APTS_Agreement__c contract) {
		Set<String> serviceCodes = new Set<String>();

		if (contract.Apttus_QPComply__RelatedProposalId__c != null) {
			// query product configuration records ordered by version number desc
			List<Apttus_Config2__ProductConfiguration__c> productConfigurations = selectProductConfigurations(contract.Apttus_QPComply__RelatedProposalId__c);

			if(!productConfigurations.isEmpty()){
				// product configurations are available. get the latest version.
				Apttus_Config2__ProductConfiguration__c productConfiguration = productConfigurations[0];
				for(Apttus_Config2__LineItem__c lineItem : productConfiguration.Apttus_Config2__LineItems__r){
					if(String.isNotBlank(lineItem.Apttus_Config2__AttributeValueId__r.APT_StarTrack_Service_Type__c)) {
						serviceCodes.add(lineItem.Apttus_Config2__AttributeValueId__r.APT_StarTrack_Service_Type__c);
					}
					if(String.isNotBlank(lineItem.Apttus_Config2__AttributeValueId__r.Service_Code_Startrack__c)){
						serviceCodes.add(lineItem.Apttus_Config2__AttributeValueId__r.Service_Code_Startrack__c);
					}
				}
			}
		}

		return new List<String>(serviceCodes);
	}

	/**
	 * Generate 'team.followerOffspringList' portion of request payload in the DSR flow.
	 *
	 * @param chargeAccountRequestId charge account request id with finalised sub account requests to include.
	 *
	 * @return generated 'team.followerOffspringList' node of request payload
	 */
	private static List<BillingAccountWrapperForTeams.StarTrackSubAccount> generateFollowerOffspringRequestPayload(Id chargeAccountRequestId) {

		// query sub account requests in 'Pending Charge Account' status (i.e. has been finalised) linked to
		// charge account request id. ensure all required fields are queried via field overrides.

		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
			APT_Sub_Account__c.SObjectType => new Set<SObjectField>{
					APT_Sub_Account__c.Id, APT_Sub_Account__c.Sub_Account_Name__c, APT_Sub_Account__c.APT_Sub_Account_Request_Status__c,
					APT_Sub_Account__c.APT_Billing_Account__c, APT_Sub_Account__c.ParentBillingAccount__c, APT_Sub_Account__c.ParentAccountRequest__c,
					APT_Sub_Account__c.APT_Sub_Account_Contact_Telephone__c, APT_Sub_Account__c.APT_Sub_Account_Contact_Email_Address__c,
					APT_Sub_Account__c.APT_Postal_Address_Street_Number__c, APT_Sub_Account__c.APT_Postal_Address_Street_Name__c,
					APT_Sub_Account__c.APT_Postal_Address_Street_Type__c, APT_Sub_Account__c.APT_Postal_Address_Suburb__c,
					APT_Sub_Account__c.APT_Postal_Address_Street_Postcode__c, APT_Sub_Account__c.APT_Street_Address_Street_Number__c,
					APT_Sub_Account__c.APT_Street_Address_Street_Name__c, APT_Sub_Account__c.APT_Street_Address_Street_Type__c,
					APT_Sub_Account__c.APT_Street_Address_Suburb__c, APT_Sub_Account__c.APT_Street_Address_Street_Postcode__c,
					APT_Sub_Account__c.AccountType__c, APT_Sub_Account__c.APT_Charge_Account__c

			},
			Contact.SObjectType => new Set<SObjectField>{
					Contact.Id, Contact.Email, Contact.FirstName, Contact.LastName, Contact.Salutation, Contact.Title,
					Contact.Phone, Contact.MobilePhone
			},
			Billing_Account__c.SObjectType => new Set<SObjectField>{
					Billing_Account__c.Id, Billing_Account__c.Organisation__c, Billing_Account__c.ABN__c, Billing_Account__c.ACN__c,
					Billing_Account__c.LEGACY_ID__c
			}
		};

		List<APT_Sub_Account__c> subAccountRequests = ((SubAccountRequestsSelector) SubAccountRequestsSelector.newInstance()
				.setFieldOverrides(fieldOverrides))
				.selectByChargeAcountRequestIdAndStatus(
						new Set<Id>{chargeAccountRequestId},
						new Set<String>{'Pending Charge Account'},
						new Set<Object>{
								SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT,
								SubAccountRequestsSelector.Options.WITH_BILLING_ACCOUNT,
								SubAccountRequestsSelector.Options.WITH_ST_PARENT_BILLING_ACCOUNT
						}
				).values();

		// generate the payload for selected sub account request records.
		return generateFollowerOffspringPayload(subAccountRequests);
	}

	/**
	 * Generate 'team.followerOffspringList' portion of request payload for sub account request records passed in.
	 *
	 * @param subAccountRequests sub account request records to source data from.
	 *
	 * @return generated 'team.followerOffspringList' node of request payload
	 */
	private static List<BillingAccountWrapperForTeams.StarTrackSubAccount> generateFollowerOffspringPayload(List<APT_Sub_Account__c> subAccountRequests) {
		List<BillingAccountWrapperForTeams.StarTrackSubAccount> subAccounts = new List<BillingAccountWrapperForTeams.StarTrackSubAccount>();
		for (APT_Sub_Account__c subAccountRequest: subAccountRequests) {
			BillingAccountWrapperForTeams.StarTrackSubAccount subAccount = new BillingAccountWrapperForTeams.StarTrackSubAccount(subAccountRequest.Id, subAccountRequest.Sub_Account_Name__c);
			// populate parent based on the account type set in sub account request.
			if (subAccountRequest.AccountType__c == INVOICE_PAID_BY_LEADER_ACCOUNT_TYPE) {
				subAccount.parentObjectId = subAccountRequest.APT_Charge_Account__c;
				subAccount.parentBillingAccountNo = subAccountRequest.APT_Billing_Account__r?.LEGACY_ID__c;
			} else if (subAccountRequest.AccountType__c == INVOICE_PAID_BY_OTHER_ACCOUNT_TYPE) {
				subAccount.parentObjectId = subAccountRequest.ParentAccountRequest__c;
				subAccount.parentBillingAccountNo = subAccountRequest.ParentBillingAccount__r?.LEGACY_ID__c;
			}

			// populate primary and secondary contacts on sub account
			if (subAccountRequest.SubAccountContact__r != null) {
				subAccount.primaryContact = new BillingAccountWrapperForTeams.Contact(subAccountRequest.SubAccountContact__r);
				subAccount.secondaryContact = new BillingAccountWrapperForTeams.Contact();
				subAccount.secondaryContact.firstName = NEW_ACCOUNT_SECONDARY_CONTACT_FIRSTNAME;
				subAccount.secondaryContact.lastName = NEW_ACCOUNT_SECONDARY_CONTACT_LASTNAME;
				subAccount.secondaryContact.jobTitle = NEW_ACCOUNT_SECONDARY_CONTACT_JOB_TITLE;
				subAccount.secondaryContact.salutation = '';
				subAccount.secondaryContact.phone = subAccountRequest.APT_Sub_Account_Contact_Telephone__c;
				subAccount.secondaryContact.email = subAccountRequest.APT_Sub_Account_Contact_Email_Address__c;

				subAccount.phone = (subAccountRequest.SubAccountContact__r?.Phone != null ? subAccountRequest.SubAccountContact__r?.Phone : subAccountRequest.SubAccountContact__r?.MobilePhone);
			}

			// populate billing address.
			String billingStreet = joinStreetAddressComponents(subAccountRequest.APT_Postal_Address_Street_Number__c, subAccountRequest.APT_Postal_Address_Street_Name__c, subAccountRequest.APT_Postal_Address_Street_Type__c);
			subAccount.billingAddress = new BillingAccountWrapperForTeams.Address(billingStreet, subAccountRequest.APT_Postal_Address_Suburb__c, subAccountRequest.APT_Postal_Address_Street_Postcode__c, true);

			// populate mailing address.
			String mailingStreet = joinStreetAddressComponents(subAccountRequest.APT_Street_Address_Street_Number__c, subAccountRequest.APT_Street_Address_Street_Name__c, subAccountRequest.APT_Street_Address_Street_Type__c);
			subAccount.mailingAddress = new BillingAccountWrapperForTeams.Address(mailingStreet, subAccountRequest.APT_Street_Address_Suburb__c, subAccountRequest.APT_Street_Address_Street_Postcode__c, true);

			subAccounts.add(subAccount);
		}
		return subAccounts;
	}

	/**
	 * Check pre-conditions are satisfied for provisioning new billing accounts in DSR flow.
	 *
	 * @param request generated request payload
	 * @param dealSupportRequest deal support request with source data
	 *
	 * @return results of preconditions check
	 */
	private static PreConditionsCheckResult checkProvisioningPreConditions(BillingAccountWrapperForTeams request, Deal_Support_Request__c dealSupportRequest) {
		PreConditionsCheckResult result = new PreConditionsCheckResult(dealSupportRequest, request);

		if (String.isNotBlank(dealSupportRequest.Integration_Status__c)) {
			// this DSR has already been submitted. no need to validate.
			result.isValid = false;
			result.status = PreConditionsCheckStatus.PREVIOUSLY_SUBMITTED.name();
			return result;
		}

		if(String.isEmpty(request.team.organisations?.billingAddress?.addressLine1)
			|| String.isEmpty(request.team.organisations?.billingAddress?.suburb)
			|| request.team.organisations?.billingAddress?.postcode == null) {

			result.addErrorMessage(System.Label.StarTrackBillingAddressRequiredForNewAccountsErrorMessage);
		}

		if(String.isEmpty(request.team.organisations?.mailingAddress?.addressLine1)
			|| String.isEmpty(request.team.organisations?.mailingAddress?.suburb)
			|| (request.team.organisations?.mailingAddress?.postcode == null)) {

			result.addErrorMessage(System.Label.StarTrackMailingAddressRequiredForNewAccountsErrorMessage);
		}

		if(String.isEmpty(request.team.organisations?.abn)){
			result.addErrorMessage(System.Label.StarTrackABNRequiredForNewAccountsErrorMessage);
		}

		if(String.isEmpty(request.team.organisations?.primaryContact?.firstName)){
			result.addErrorMessage(System.Label.StarTrackContactFirstNameRequiredForNewAccountsErrorMessage);
		}
		if(String.isEmpty(request.team.organisations?.primaryContact?.lastName)){
			result.addErrorMessage(System.Label.StarTrackContactLastNameRequiredForNewAccountsErrorMessage);
		}
		if(String.isEmpty(request.team.organisations?.primaryContact?.email)){
			result.addErrorMessage(System.Label.StarTrackContactEmailRequiredForNewAccountsErrorMessage);
		}

		if(String.isEmpty(dealSupportRequest.APT_Contract__r?.Apttus_QPComply__RelatedProposalId__r?.APT_Credit_Assessment__r?.APT_Charge_Account__c)){
			result.addErrorMessage(System.Label.StarTrackChargeAccountRequestIdRequiredForNewAccountsErrorMessage);
		}

		if(request.team.creditDetails?.creditLimit == null){
			result.addErrorMessage(System.Label.StarTrackCreditLimitRequiredForNewAccountsErrorMessage);
		}

		if(request.team.creditDetails?.creditLimit == null || Integer.ValueOf(request.team.creditDetails?.creditLimit) <= 10){
			result.addErrorMessage(System.Label.StarTrackCreditLimitMustBeHigherForNewAccountsErrorMessage);
		}

		if(request.team.creditDetails?.estimatedMonthlyRevenue == null){
			result.addErrorMessage(System.Label.StarTrackEstimatedMonthlyRevenueRequiredForNewAccountsErrorMessage);
		}
		if((request.team.creditDetails?.nextRevenueDueDate == null)){
			result.addErrorMessage(System.Label.StarTrackNextRevenueDateRequiredForNewAccountsErrorMessage);
		}

		List<Organisation_Role__c> roles = ((OrganisationRoleSelector) OrganisationRoleSelector.newInstance().setFieldOverrides(new Set<SObjectField>{
				Organisation_Role__c.Id, Organisation_Role__c.Organisation__c, Organisation_Role__c.Role_Type__c
		})).selectByOrganisationId(new Set<Id>{dealSupportRequest.Organisation__c});

		if (roles.size() > 1){
			result.addErrorMessage(System.Label.StarTrackOnlyOneOrganisationRoleAllowedForNewAccountsErrorMessage);
		}

		if (!VALID_ORGANISATION_ROLE_TYPES.contains(dealSupportRequest.Organisation__r?.Role_Type_Roll_Up__c)) {
			result.addErrorMessage(System.Label.StarTrackOrganisationRoleInvalidForNewAccountsErrorMessage);
		}

		if(!VALID_CREDIT_ASSESSMENT_STATUS.contains(dealSupportRequest.APT_Contract__r?.Apttus_QPComply__RelatedProposalId__r?.APT_Credit_Assessment__r?.APT_Credit_Assessment_Status__c)){
			result.addErrorMessage(System.Label.StarTrackCreditAssessmentStatusInvalidForNewAccountsErrorMessage);
		}

		return result;
	}

	/**
	 * Join individual street address components to get street address.
	 * @param streetNumber street number to include
	 * @param streetName street name to include
	 * @param streetType street type to include
	 *
	 * @return concatenated street address
	 */
	private static String joinStreetAddressComponents(String streetNumber, String streetName, String streetType) {
		// join street address components with whitespace as the separator
		String streetAddress = String.join(new List<String>{streetNumber, streetName, streetType}, ' ');
		// ensure contiguous whitespaces are collapsed into one
		return streetAddress.replaceAll('\\s+', ' ');
	}

	/**
	 * Query deal support request record and all related records required for generating provisioning request in DSR flow.
	 *
	 * @param dealSupportRequestId deal support request where provisioning is initiated from.
	 *
	 * @return deal support request with related record data
	 */
	private static Deal_Support_Request__c selectDealSupportRequest(Id dealSupportRequestId) {

		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				Deal_Support_Request__c.SObjectType => new Set<SObjectField>{
						Deal_Support_Request__c.Id, Deal_Support_Request__c.Integration_Status__c, Deal_Support_Request__c.APT_Contract__c,
						Deal_Support_Request__c.Work_Type__c, Deal_Support_Request__c.Name, Deal_Support_Request__c.Opportunity__c,
						Deal_Support_Request__c.Organisation__c, Deal_Support_Request__c.CustomerContact1__c
				},
				Apttus__APTS_Agreement__c.SObjectType => new Set<SObjectField>{
						Apttus__APTS_Agreement__c.Id, Apttus__APTS_Agreement__c.Term__c, Apttus__APTS_Agreement__c.Apttus_QPComply__RelatedProposalId__c,
						Apttus__APTS_Agreement__c.Apttus__Contract_Start_Date__c, Apttus__APTS_Agreement__c.Apttus__Contract_End_Date__c
				},
				Account.SObjectType => new Set<SObjectField>{
						Account.Id, Account.ShippingStreet, Account.ShippingCity, Account.ShippingState, Account.ShippingPostalCode,
						Account.Name, Account.Organisation_Trading_Name__c, Account.BillingCity, Account.BillingPostalCode,
						Account.BillingStreet, Account.ABN__c, Account.ACN__c, Account.Role_Type_Roll_Up__c
				},
				Opportunity.SObjectType => new Set<SObjectField>{
						Opportunity.Id, Opportunity.Sender_name_to_appear_on_parcel_label__c, Opportunity.Primary_Pick_Up_Location__c
				},
				Contact.SObjectType => new Set<SObjectField>{
						Contact.Id, Contact.Email, Contact.FirstName, Contact.LastName, Contact.Salutation, Contact.Title,
						Contact.Phone, Contact.MobilePhone
				},
				Apttus_Proposal__Proposal__c.SObjectType => new Set<SObjectField>{
						Apttus_Proposal__Proposal__c.Id, Apttus_Proposal__Proposal__c.APT_Credit_Assessment__c,
						Apttus_Proposal__Proposal__c.APT_Method_of_Payment__c, Apttus_Proposal__Proposal__c.APT_Minimum_Monthly_Spend__c
				},
				APT_Credit_Assessment__c.SObjectType => new Set<SObjectField>{
						APT_Credit_Assessment__c.Id, APT_Credit_Assessment__c.APT_Charge_Account__c, APT_Credit_Assessment__c.APT_Credit_Assessment_Status__c,
						APT_Credit_Assessment__c.Name, APT_Credit_Assessment__c.StarTrack_Proposed_for_New_Account__c
				}
		};

		return DealSupportRequestsSelector.newInstance(fieldOverrides).selectById(new Set<Id>{dealSupportRequestId}, new Set<Object>{
				DealSupportRequestsSelector.Options.WITH_CONTRACT,
				DealSupportRequestsSelector.Options.WITH_ORGANISATION,
				DealSupportRequestsSelector.Options.WITH_OPPORTUNITY,
				DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT,
				DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT,
				ApttusContractsSelector.Options.WITH_PROPOSAL
		}).get(dealSupportRequestId);
	}

	/**
	 * Query primary pickup location associated with the opportunity
	 * @param opportunity opportunity record
	 *
	 * @return pickup location
	 */
	private static Pick_Up_Location__c selectPickupLocation(Opportunity opportunity) {
		if (opportunity?.Primary_Pick_Up_Location__c != null) {
			List<Pick_Up_Location__c> pickUpLocations = PickUpLocationSelector.newInstance().selectById(new Set<Id>{opportunity?.Primary_Pick_Up_Location__c}).values();
			if(!pickUpLocations.isEmpty()){
				return pickUpLocations[0];
			}
		}
		return null;
	}

	/**
	 * Query sub account request records and all related records required for generating provisioning request in Billing Account flow.
	 *
	 * @param subAccountRequestIds sub account requests to be included in provisioning request
	 *
	 * @return sub account request records with related record data.
	 */
	private static List<APT_Sub_Account__c> selectSubAccountRequests(Set<Id> subAccountRequestIds) {
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				Billing_Account__c.SObjectType => new Set<SObjectField>{
						Billing_Account__c.Id, Billing_Account__c.Organisation__c, Billing_Account__c.ABN__c, Billing_Account__c.ACN__c,
						Billing_Account__c.LEGACY_ID__c
				},
				APT_Sub_Account__c.SObjectType => new Set<SObjectField>{
						APT_Sub_Account__c.Id, APT_Sub_Account__c.Sub_Account_Name__c, APT_Sub_Account__c.APT_Sub_Account_Request_Status__c,
						APT_Sub_Account__c.APT_Billing_Account__c, APT_Sub_Account__c.ParentBillingAccount__c, APT_Sub_Account__c.ParentAccountRequest__c,
						APT_Sub_Account__c.APT_Sub_Account_Contact_Telephone__c, APT_Sub_Account__c.APT_Sub_Account_Contact_Email_Address__c,
						APT_Sub_Account__c.APT_Postal_Address_Street_Number__c, APT_Sub_Account__c.APT_Postal_Address_Street_Name__c,
						APT_Sub_Account__c.APT_Postal_Address_Street_Type__c, APT_Sub_Account__c.APT_Postal_Address_Suburb__c,
						APT_Sub_Account__c.APT_Postal_Address_Street_Postcode__c, APT_Sub_Account__c.APT_Street_Address_Street_Number__c,
						APT_Sub_Account__c.APT_Street_Address_Street_Name__c, APT_Sub_Account__c.APT_Street_Address_Street_Type__c,
						APT_Sub_Account__c.APT_Street_Address_Suburb__c, APT_Sub_Account__c.APT_Street_Address_Street_Postcode__c,
						APT_Sub_Account__c.AccountType__c, APT_Sub_Account__c.APT_Charge_Account__c

				},
				Contact.SObjectType => new Set<SObjectField>{
						Contact.Id, Contact.Email, Contact.FirstName, Contact.LastName, Contact.Salutation, Contact.Title,
						Contact.Phone, Contact.MobilePhone
				}
		};

		return ((SubAccountRequestsSelector)SubAccountRequestsSelector.newInstance().setFieldOverrides(fieldOverrides)).selectByIds(subAccountRequestIds, new Set<Object>{
				SubAccountRequestsSelector.Options.WITH_BILLING_ACCOUNT,
				SubAccountRequestsSelector.Options.WITH_ST_PARENT_BILLING_ACCOUNT,
				SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT
		}).values();
	}

	/**
	 * Query product configuration records and all related records required for generating provisioning request.
	 *
	 * @param proposalId apttus proposal to retrieve product configurations for
	 *
	 * @return product configuration records with related record data.
	 */
	private static List<Apttus_Config2__ProductConfiguration__c> selectProductConfigurations(Id proposalId) {
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				Apttus_Config2__ProductConfiguration__c.SObjectType => new Set<SObjectField>{Apttus_Config2__ProductConfiguration__c.Id},
				Apttus_Config2__LineItem__c.SObjectType => new Set<SObjectField>{Apttus_Config2__LineItem__c.Id},
				Apttus_Config2__ProductAttributeValue__c.SObjectType => new Set<SObjectField>{
						Apttus_Config2__ProductAttributeValue__c.Id, Apttus_Config2__ProductAttributeValue__c.APT_StarTrack_Service_Type__c,
						Apttus_Config2__ProductAttributeValue__c.Service_Code_Startrack__c
				}
		};

		// query the latest version of product configuration record. only interested in latest version.
		return ProductConfigurationSelector.newInstance(1, fieldOverrides)
				.search(new Map<String, Object>{
						'proposalIds' => new Set<Id>{proposalId},
						'status' => new Set<String>{'Finalized'}
				}, new Set<Object>{
						ProductConfigurationSelector.Options.WITH_LINE_ITEMS,
						LineItemsSelector.Options.WITH_PRODUCT_ATTRIBUTE_VALUE
				}, true, Apttus_Config2__ProductConfiguration__c.Apttus_Config2__VersionNumber__c, 'DESC');
	}

	/**
	 * Create a new external onboarding request record to capture callout request/response details.
	 *
	 * @param request request payload to be sent
	 *
	 * @return provisioning details including newly generated external onboarding request id
	 */
	private static BillingAccountProvisioningDetails createNewExternalOnboardingRequest(BillingAccountWrapperForTeams request) {
		BAMExternalOnboardingRequest__c externalOnboardingRequest = new BAMExternalOnboardingRequest__c();
		externalOnboardingRequest.Request_Object_Name__c = String.valueOf(Id.valueOf(request.requestObjId).getSobjectType());
		externalOnboardingRequest.Request_Object_Id__c = request.requestObjId;
		externalOnboardingRequest.Request_Date__c = System.now();
		externalOnboardingRequest.RecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName(String.valueOf(BAMExternalOnboardingRequest__c.SObjectType), new Set<String>{'Billing_Account_Creation'}).values()[0].Id;
		externalOnboardingRequest.Target_System__c = request.targetSystem;
		ApplicationDatabase.getInstance().dmlInsert(new List<BAMExternalOnboardingRequest__c>{externalOnboardingRequest});

		request.transactionId = String.valueOf(externalOnboardingRequest.Id);

		BAMExternalOnboardingRequest__c updatable = new BAMExternalOnboardingRequest__c(Id=externalOnboardingRequest.Id);
		updatable.Request_Payload__c = JSON.serialize(request, true);
		ApplicationDatabase.getInstance().dmlUpdate(new List<BAMExternalOnboardingRequest__c>{updatable});

		BillingAccountProvisioningDetails response = new BillingAccountProvisioningDetails();
		response.externalOnboardingRequestId = externalOnboardingRequest.Id;
		response.requestPayload = request;
		return response;
	}

	/**
	 * Possible status for pre conditions check
	 */
	public enum PreConditionsCheckStatus {
		READY_FOR_SUBMISSION, PREVIOUSLY_SUBMITTED, PRECONDITIONS_NOT_MET
	}

	/**
	 * Pre Condition check results returned to user interface
	 */
	public class PreConditionsCheckResult {

		@AuraEnabled public SObject dealSupportRequest;

		@AuraEnabled public Object requestPayload;

		@AuraEnabled public Boolean isValid = true;

		@AuraEnabled public String status = PreConditionsCheckStatus.READY_FOR_SUBMISSION.name();

		@AuraEnabled public List<String> errorMessages = new List<String>();

		public PreConditionsCheckResult(SObject dealSupportRequest, Object requestPayload) {
			this.dealSupportRequest = dealSupportRequest;
			this.requestPayload = requestPayload;
		}

		public void addErrorMessage(String error) {
			this.errorMessages.add(error);
			this.isValid = false;
			this.status = PreConditionsCheckStatus.PRECONDITIONS_NOT_MET.name();
		}
	}

	public class BillingAccountProvisioningDetails {
		@AuraEnabled public Id externalOnboardingRequestId;
		@AuraEnabled public BillingAccountWrapperForTeams requestPayload;
	}

	/**
	 * State information passed into continuation callback
	 */
	public class AsyncExecutionContext {
		public String processType;
		public String requestObjId;
		public String chargeAccountRequestId;
		public String onboardingRequestId;
		public Set<Id> subAccountRequestIds = new Set<Id>();
	}
}