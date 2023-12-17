/**
 * @description
 * Test class for ProvisionSTBillingAccountsController
 * @author Ranjeewa Silva
 * @group Tests
 * @changelog
 * 2023-10-30 - Ranjeewa Silva - Created
 */
@IsTest
private class ProvisionSTBillingAccountController_Test {

	/**
	 * Test to ensure pre condition check returns all errors when required fields are blank.
	 */
	@IsTest
	private static void testPreconditionsCheckWhenRequiredFieldsBlank() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		// setup apttus contract, proposal and credit assessment records
		Apttus__APTS_Agreement__c apttusContract = getApttusContractWithRelatedContactAndProposal(primaryContact, opportunity.Id, chargeAccountRequest.Id);
		// setup sub account requests to be included in the same provisioning request
		List<APT_Sub_Account__c> subAccountRequests = ApplicationTestDataFactory.getSubAccountRequest(2, 'test', true);
		for (APT_Sub_Account__c subAccountRequest: subAccountRequests) {
			subAccountRequest.SubAccountContact__c = primaryContact.Id;
		}
		subAccountRequests[0] = (APT_Sub_Account__c) ApplicationTestDataFactory.setUnwritableFields(subAccountRequests[0], new Map<String, Object>{
				'SubAccountContact__r' => primaryContact
		});
		subAccountRequests[1] = (APT_Sub_Account__c) ApplicationTestDataFactory.setUnwritableFields(subAccountRequests[1], new Map<String, Object>{
				'SubAccountContact__r' => primaryContact
		});

		// setup deal support request to initiate billing account provisioning
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunity.Id, account.Id, true)[0];
		dealSupportRequest.APT_Contract__c = apttusContract.Id;
		dealSupportRequest = (Deal_Support_Request__c) ApplicationTestDataFactory.setUnwritableFields(dealSupportRequest, new Map<String, Object>{
				'Organisation__r' => account,
				'APT_Contract__r' => apttusContract,
				'Opportunity__r' => opportunity
		});

		// =====================================
		// Stubbing
		// =====================================
		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		SubAccountRequestsSelector subAccountRequestsSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(dsrSelector.selectById(new Set<Id>{dealSupportRequest.Id}, new Set<Object>{
				DealSupportRequestsSelector.Options.WITH_CONTRACT,
				DealSupportRequestsSelector.Options.WITH_ORGANISATION,
				DealSupportRequestsSelector.Options.WITH_OPPORTUNITY,
				DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT,
				DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT,
				ApttusContractsSelector.Options.WITH_PROPOSAL
		})).thenReturn(new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest});

		MockUtility.Mocks.when(subAccountRequestsSelector.selectByChargeAcountRequestIdAndStatus(
				(Set<Id>)fflib_Match.anyObject(),
				(Set<String>)fflib_Match.anyObject(),
				(Set<Object>)fflib_Match.anyObject()
		)).thenReturn(new Map<Id, APT_Sub_Account__c>(subAccountRequests));

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ProvisionSTBillingAccountsController.PreConditionsCheckResult preConditionsCheckResult = ProvisionSTBillingAccountsController.checkBillingAccountProvisioningPreconditions(dealSupportRequest.Id);
		Test.stopTest();

		Assert.isNotNull(preConditionsCheckResult, 'Expected a valid results with success/failure status and error messages, but got null.');
		Assert.isNotNull(preConditionsCheckResult.dealSupportRequest, 'Initiating deal support request record details must be returned with the results.');
		Assert.areEqual(dealSupportRequest.Id, preConditionsCheckResult.dealSupportRequest.Id, 'Initiating deal support request record details must be returned with the results.');
		Assert.isFalse(preConditionsCheckResult.isValid, 'Expected pre condition check to return isValid=false due to required fields not populated.');
		Assert.areEqual(ProvisionSTBillingAccountsController.PreConditionsCheckStatus.PRECONDITIONS_NOT_MET.name(), preConditionsCheckResult.status, 'Expected pre condition check to return error status due to required fields not populated.');
		Assert.isFalse(preConditionsCheckResult.errorMessages.isEmpty(), 'Errors due to missing required fields are not returned in pre condition check results.');
	}

	/**
	 * Test to ensure pre condition check returns all errors when required fields are blank.
	 */
	@IsTest
	private static void testPreconditionsCheckWhenDSRPreviouslySubmitted() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		// setup apttus contract, proposal and credit assessment records
		Apttus__APTS_Agreement__c apttusContract = getApttusContractWithRelatedContactAndProposal(primaryContact, opportunity.Id, chargeAccountRequest.Id);
		// setup sub account requests to be included in the same provisioning request
		List<APT_Sub_Account__c> subAccountRequests = ApplicationTestDataFactory.getSubAccountRequest(2, 'test', true);
		for (APT_Sub_Account__c subAccountRequest: subAccountRequests) {
			subAccountRequest.SubAccountContact__c = primaryContact.Id;
		}
		subAccountRequests[0] = (APT_Sub_Account__c) ApplicationTestDataFactory.setUnwritableFields(subAccountRequests[0], new Map<String, Object>{
				'SubAccountContact__r' => primaryContact
		});
		subAccountRequests[1] = (APT_Sub_Account__c) ApplicationTestDataFactory.setUnwritableFields(subAccountRequests[1], new Map<String, Object>{
				'SubAccountContact__r' => primaryContact
		});

		// setup deal support request to initiate billing account provisioning
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunity.Id, account.Id, true)[0];
		dealSupportRequest.APT_Contract__c = apttusContract.Id;
		dealSupportRequest.Integration_Status__c = 'Requested';
		dealSupportRequest = (Deal_Support_Request__c) ApplicationTestDataFactory.setUnwritableFields(dealSupportRequest, new Map<String, Object>{
				'Organisation__r' => account,
				'APT_Contract__r' => apttusContract,
				'Opportunity__r' => opportunity
		});

		// =====================================
		// Stubbing
		// =====================================
		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		SubAccountRequestsSelector subAccountRequestsSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(dsrSelector.selectById(new Set<Id>{dealSupportRequest.Id}, new Set<Object>{
				DealSupportRequestsSelector.Options.WITH_CONTRACT,
				DealSupportRequestsSelector.Options.WITH_ORGANISATION,
				DealSupportRequestsSelector.Options.WITH_OPPORTUNITY,
				DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT,
				DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT,
				ApttusContractsSelector.Options.WITH_PROPOSAL
		})).thenReturn(new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest});

		MockUtility.Mocks.when(subAccountRequestsSelector.selectByChargeAcountRequestIdAndStatus(
				(Set<Id>)fflib_Match.anyObject(),
				(Set<String>)fflib_Match.anyObject(),
				(Set<Object>)fflib_Match.anyObject()
		)).thenReturn(new Map<Id, APT_Sub_Account__c>(subAccountRequests));

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ProvisionSTBillingAccountsController.PreConditionsCheckResult preConditionsCheckResult = ProvisionSTBillingAccountsController.checkBillingAccountProvisioningPreconditions(dealSupportRequest.Id);
		Test.stopTest();

		Assert.isNotNull(preConditionsCheckResult, 'Expected a valid results with success/failure status and error messages, but got null.');
		Assert.isNotNull(preConditionsCheckResult.dealSupportRequest, 'Initiating deal support request record details must be returned with the results.');
		Assert.areEqual(dealSupportRequest.Id, preConditionsCheckResult.dealSupportRequest.Id, 'Initiating deal support request record details must be returned with the results.');
		Assert.areEqual(ProvisionSTBillingAccountsController.PreConditionsCheckStatus.PREVIOUSLY_SUBMITTED.name(), preConditionsCheckResult.status, 'Expected pre condition check to return PREVIOUSLY_SUBMITTED status if DSR has been already submitted.');
	}

	/**
	 * Test to ensure pre condition check returns success status with no errors when all pre conditions are met.
	 */
	@IsTest
	private static void testPreconditionsCheckWhenAllPreconditionsAreSatisfied() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		account.ABN__c = '11111111111';
		account.BillingStreet = 'test street';
		account.BillingCity = 'test';
		account.BillingPostalCode = '3000';
		account.BillingState = 'VIC';
		account.BillingCountry = 'Australia';
		account.Sales_Segment__c = 'Test Segment 1234';
		account = (Account) ApplicationTestDataFactory.setUnwritableFields(account, new Map<String, Object>{
				'Role_Type_Roll_Up__c' => ProvisionSTBillingAccountsController.VALID_ORGANISATION_ROLE_TYPES.iterator().next()
		});

		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		// setup CSQ and Pickup Location for opportunity
		Pick_Up_Location__c pickUpLocation = getPickupLocation(opportunity.Id);
		opportunity.Primary_Pick_Up_Location__c = pickupLocation.Id;

		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];

		// setup apttus contract, proposal and credit assessment records
		Apttus__APTS_Agreement__c apttusContract = getApttusContractWithRelatedContactAndProposal(primaryContact, opportunity.Id, chargeAccountRequest.Id);

		// setup sub account requests to be included in the same provisioning request
		List<APT_Sub_Account__c> subAccountRequests = ApplicationTestDataFactory.getSubAccountRequest(2, 'test', true);
		subAccountRequests[0].AccountType__c = ProvisionSTBillingAccountsController.INVOICE_PAID_BY_LEADER_ACCOUNT_TYPE;
		subAccountRequests[1].AccountType__c = ProvisionSTBillingAccountsController.INVOICE_PAID_BY_OTHER_ACCOUNT_TYPE;
		for (APT_Sub_Account__c subAccountRequest: subAccountRequests) {
			subAccountRequest.SubAccountContact__c = primaryContact.Id;
		}
		subAccountRequests[0] = (APT_Sub_Account__c) ApplicationTestDataFactory.setUnwritableFields(subAccountRequests[0], new Map<String, Object>{
				'SubAccountContact__r' => primaryContact
		});
		subAccountRequests[1] = (APT_Sub_Account__c) ApplicationTestDataFactory.setUnwritableFields(subAccountRequests[1], new Map<String, Object>{
				'SubAccountContact__r' => primaryContact
		});

		// setup deal support request to initiate billing account provisioning
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunity.Id, account.Id, true)[0];
		dealSupportRequest.APT_Contract__c = apttusContract.Id;
		dealSupportRequest = (Deal_Support_Request__c) ApplicationTestDataFactory.setUnwritableFields(dealSupportRequest, new Map<String, Object>{
				'Organisation__r' => account,
				'APT_Contract__r' => apttusContract,
				'Opportunity__r' => opportunity
		});

		Sales_Team_Segment__c salesTeamSegment = ApplicationTestDataFactorySales.getSalesTeamSegments(1, true)[0];
		salesTeamSegment.Name = account.Sales_Segment__c;
		salesTeamSegment.CreditPersonCode__c = 'CO 12345';

		// =====================================
		// Stubbing
		// =====================================
		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		PickUpLocationSelector pickupLocationsSelector = (PickUpLocationSelector)MockUtility.mockSelector(PickUpLocationSelector.class);
		SubAccountRequestsSelector subAccountRequestsSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		SalesTeamSegmentsSelector salesTeamSegmentsSelector = (SalesTeamSegmentsSelector)MockUtility.mockSelector(SalesTeamSegmentsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(dsrSelector.selectById(new Set<Id>{dealSupportRequest.Id}, new Set<Object>{
				DealSupportRequestsSelector.Options.WITH_CONTRACT,
				DealSupportRequestsSelector.Options.WITH_ORGANISATION,
				DealSupportRequestsSelector.Options.WITH_OPPORTUNITY,
				DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT,
				DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT,
				ApttusContractsSelector.Options.WITH_PROPOSAL
		})).thenReturn(new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest});

		MockUtility.Mocks.when(pickupLocationsSelector.selectById(new Set<Id>{opportunity.Primary_Pick_Up_Location__c})).thenReturn(new Map<Id, Pick_Up_Location__c>{pickupLocation.Id => pickupLocation});

		MockUtility.Mocks.when(subAccountRequestsSelector.selectByChargeAcountRequestIdAndStatus(
				(Set<Id>)fflib_Match.anyObject(),
				(Set<String>)fflib_Match.anyObject(),
				(Set<Object>)fflib_Match.anyObject()
		)).thenReturn(new Map<Id, APT_Sub_Account__c>(subAccountRequests));

		MockUtility.Mocks.when(salesTeamSegmentsSelector.selectByName(new Set<String>{account.Sales_Segment__c})).thenReturn(new List<Sales_Team_Segment__c>{salesTeamSegment});

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ProvisionSTBillingAccountsController.PreConditionsCheckResult preConditionsCheckResult = ProvisionSTBillingAccountsController.checkBillingAccountProvisioningPreconditions(dealSupportRequest.Id);
		Test.stopTest();

		Assert.isNotNull(preConditionsCheckResult, 'Expected a valid results with success/failure status and error messages, but got null.');
		Assert.isNotNull(preConditionsCheckResult.dealSupportRequest, 'Initiating deal support request record details must be returned with the results.');
		Assert.areEqual(dealSupportRequest.Id, preConditionsCheckResult.dealSupportRequest.Id, 'Initiating deal support request record details must be returned with the results.');
		Assert.isTrue(preConditionsCheckResult.isValid, 'Expected pre condition check to return isValid=true when all pre conditions are satisfied.');
		Assert.areEqual(ProvisionSTBillingAccountsController.PreConditionsCheckStatus.READY_FOR_SUBMISSION.name(), preConditionsCheckResult.status, 'Expected pre condition check to return success status when all conditions are satisfied.');
		Assert.isTrue(preConditionsCheckResult.errorMessages.isEmpty(), 'No errors are expected in pre condition check results.');

		Assert.isInstanceOfType(preConditionsCheckResult.requestPayload, BillingAccountWrapperForTeams.class, 'Generated request payload is not valid for Star Track billing ccount provisioning');
		BillingAccountWrapperForTeams requestPayload = (BillingAccountWrapperForTeams) preConditionsCheckResult.requestPayload;
		Assert.areEqual('TEAM', requestPayload.targetSystem, 'Request payload \'targetSystem\' must be set to \'TEAM\'.');
		Assert.areEqual(account.ABN__c, requestPayload.team.organisations.abn, 'Request payload \'team.organisations.abn\' must be set to customer organisation\'s ABN.');
		Assert.areEqual(BillingAccountWrapperForTeams.REQUEST_PAYLOAD_BLANK_ACN_IDENTIFIER, requestPayload.team.organisations.acn, 'Request payload \'team.organisations.acn\' must be set to identifier string when customer organisation ACN is blank.');
		Assert.areEqual(primaryContact.LastName, requestPayload.team.organisations.primaryContact.lastName, 'Request payload \'team.organisations.primaryContact.lastName\' must be set to last name of primary contact on apttus cntract.');
		Assert.areEqual(primaryContact.FirstName, requestPayload.team.organisations.primaryContact.firstName, 'Request payload \'team.organisations.primaryContact.firstName\' must be set to first name of primary contact on apttus cntract.');
		Assert.areEqual(primaryContact.Email, requestPayload.team.organisations.primaryContact.email, 'Request payload \'team.organisations.primaryContact.email\' must be set to email of primary contact on apttus cntract.');
		Assert.areEqual(primaryContact.Email, requestPayload.team.organisations.secondaryContact.email, 'Request payload \'team.organisations.secondaryContact.email\' must also be set to email of primary contact on apttus cntract.');
		Assert.areEqual(account.BillingStreet, requestPayload.team.organisations.billingAddress.addressLine1, 'Request payload \'team.organisations.billingAddress.addressLine1\' must be set to BillingStreet on customer organisation.');
		Assert.isNull(requestPayload.team.organisations.billingAddress.addressLine2, 'Request payload \'team.organisations.billingAddress.addressLine2\' must be blank when BillingStreet is < 25 characters in length.');
		Assert.areEqual(account.BillingCity, requestPayload.team.organisations.billingAddress.suburb, 'Request payload \'team.organisations.billingAddress.suburb\' must be set to BillingCity on customer organisation.');
		Assert.areEqual(account.BillingPostalCode, String.valueOf(requestPayload.team.organisations.billingAddress.postcode), 'Request payload \'team.organisations.billingAddress.postcode\' must be set to BillingPostalCode on customer organisation.');
		Assert.areEqual(pickUpLocation.Address__c, requestPayload.team.organisations.mailingAddress.addressLine1, 'Request payload \'team.organisations.mailingAddress.addressLine1\' must be set to pickup location\'s street address.');
		Assert.isNull(requestPayload.team.organisations.mailingAddress.addressLine2, 'Request payload \'team.organisations.mailingAddress.addressLine2\' must be blank when Pickup Location street address is < 25 characters in length.');
		Assert.areEqual(pickUpLocation.Suburb__c, requestPayload.team.organisations.mailingAddress.suburb, 'Request payload \'team.organisations.mailingAddress.suburb\' must be set to pickup location\'s suburb.');
		Assert.areEqual(pickUpLocation.Postcode__c, String.valueOf(requestPayload.team.organisations.mailingAddress.postcode), 'Request payload \'team.organisations.mailingAddress.postcode\' must be set to pickup location\'s post code.');
		Assert.areEqual(salesTeamSegment.CreditPersonCode__c, requestPayload.team.creditDetails.creditOfficer, 'Request payload \'team.creditDetails.creditOfficer\' must be set to credit officer specified on Sales Team Segment.');
		BillingAccountCreationConfiguration__mdt metadata = ProvisionSTBillingAccountsController.billingAccountCreationConfigurationMetadata;
		if (metadata != null) {
			Assert.areEqual(metadata.AnnualPriceReviewEffectiveDate__c.day(), requestPayload.team.creditDetails.nextRevenueDueDate.day(), 'Request payload \'team.creditDetails.nextRevenueDueDate\' date component must be populated based on annual price review date configured in metadata.');
			Assert.areEqual(metadata.AnnualPriceReviewEffectiveDate__c.month(), requestPayload.team.creditDetails.nextRevenueDueDate.month(), 'Request payload \'team.creditDetails.nextRevenueDueDate\' month component must be populated based on annual price review date configured in metadata.');
		}
		Assert.areEqual(subAccountRequests.size(), requestPayload.team.followerOffspringList.size(), 'Request payload does not include details of all sub account requests passed in.');
	}

	/**
	 * Test to ensure attempting to generate provisioning request throws exception when required pre-conditions are not
	 * satisfied.
	 */
	@IsTest
	private static void testGenerateProvisioningRequestThrowsExceptionIfPreConditionsNotSatisfied() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1, true)[0];
		// setup apttus contract, proposal and credit assessment records
		Apttus__APTS_Agreement__c apttusContract = getApttusContractWithRelatedContactAndProposal(primaryContact, opportunity.Id, chargeAccountRequest.Id);

		// setup sub account requests to be included in the same provisioning request
		List<APT_Sub_Account__c> subAccountRequests = ApplicationTestDataFactory.getSubAccountRequest(2, 'test', true);
		for (APT_Sub_Account__c subAccountRequest : subAccountRequests) {
			subAccountRequest.SubAccountContact__c = primaryContact.Id;
		}
		subAccountRequests[0] = (APT_Sub_Account__c) ApplicationTestDataFactory.setUnwritableFields(subAccountRequests[0], new Map<String, Object>{
				'SubAccountContact__r' => primaryContact
		});
		subAccountRequests[1] = (APT_Sub_Account__c) ApplicationTestDataFactory.setUnwritableFields(subAccountRequests[1], new Map<String, Object>{
				'SubAccountContact__r' => primaryContact
		});

		// setup deal support request to initiate billing account provisioning
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunity.Id, account.Id, true)[0];
		dealSupportRequest.APT_Contract__c = apttusContract.Id;
		dealSupportRequest = (Deal_Support_Request__c) ApplicationTestDataFactory.setUnwritableFields(dealSupportRequest, new Map<String, Object>{
				'Organisation__r' => account,
				'APT_Contract__r' => apttusContract,
				'Opportunity__r' => opportunity
		});

		// =====================================
		// Stubbing
		// =====================================
		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector) MockUtility.mockSelector(DealSupportRequestsSelector.class);
		SubAccountRequestsSelector subAccountRequestsSelector = (SubAccountRequestsSelector) MockUtility.mockSelector(SubAccountRequestsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(dsrSelector.selectById(new Set<Id>{
				dealSupportRequest.Id
		}, new Set<Object>{
				DealSupportRequestsSelector.Options.WITH_CONTRACT,
				DealSupportRequestsSelector.Options.WITH_ORGANISATION,
				DealSupportRequestsSelector.Options.WITH_OPPORTUNITY,
				DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT,
				DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT,
				ApttusContractsSelector.Options.WITH_PROPOSAL
		})).thenReturn(new Map<Id, Deal_Support_Request__c>{
				dealSupportRequest.Id => dealSupportRequest
		});

		MockUtility.Mocks.when(subAccountRequestsSelector.selectByChargeAcountRequestIdAndStatus(
				(Set<Id>) fflib_Match.anyObject(),
				(Set<String>) fflib_Match.anyObject(),
				(Set<Object>) fflib_Match.anyObject()
		)).thenReturn(new Map<Id, APT_Sub_Account__c>(subAccountRequests));

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		try {
			ProvisionSTBillingAccountsController.generateBillingAccountsProvisioningRequest(dealSupportRequest.Id);
		} catch (Exception e) {
			Assert.isInstanceOfType(e, AuraHandledException.class, 'Expected to receive an exception of type AuraHandledException, but got :' + e.getTypeName());
		}
		Test.stopTest();
	}

	/**
	 * Test to ensure provisioning request is generated successfully when required pre-conditions are satisfied.
	 */
	@IsTest
	private static void testGenerateProvisioningRequestWhenPreConditionsAreSatisfied() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		account.ABN__c = '11111111111';
		account.BillingStreet = 'test street';
		account.BillingCity = 'test';
		account.BillingPostalCode = '3000';
		account.BillingState = 'VIC';
		account.BillingCountry = 'Australia';
		account = (Account) ApplicationTestDataFactory.setUnwritableFields(account, new Map<String, Object>{
				'Role_Type_Roll_Up__c' => ProvisionSTBillingAccountsController.VALID_ORGANISATION_ROLE_TYPES.iterator().next()
		});

		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		// setup pickup location for opportunity
		Pick_Up_Location__c pickUpLocation = getPickupLocation(opportunity.Id);
		opportunity.Primary_Pick_Up_Location__c = pickupLocation.Id;

		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
		// setup apttus contract, proposal and credit assessment records
		Apttus__APTS_Agreement__c apttusContract = getApttusContractWithRelatedContactAndProposal(primaryContact, opportunity.Id, chargeAccountRequest.Id);

		// setup sub account requests to be included in the same provisioning request
		List<APT_Sub_Account__c> subAccountRequests = ApplicationTestDataFactory.getSubAccountRequest(2, 'test', true);
		subAccountRequests[0].AccountType__c = ProvisionSTBillingAccountsController.INVOICE_PAID_BY_LEADER_ACCOUNT_TYPE;
		subAccountRequests[1].AccountType__c = ProvisionSTBillingAccountsController.INVOICE_PAID_BY_OTHER_ACCOUNT_TYPE;
		for (APT_Sub_Account__c subAccountRequest: subAccountRequests) {
			subAccountRequest.SubAccountContact__c = primaryContact.Id;
		}
		subAccountRequests[0] = (APT_Sub_Account__c) ApplicationTestDataFactory.setUnwritableFields(subAccountRequests[0], new Map<String, Object>{
				'SubAccountContact__r' => primaryContact
		});
		subAccountRequests[1] = (APT_Sub_Account__c) ApplicationTestDataFactory.setUnwritableFields(subAccountRequests[1], new Map<String, Object>{
				'SubAccountContact__r' => primaryContact
		});

		// setup deal support request to initiate billing account provisioning
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunity.Id, account.Id, true)[0];
		dealSupportRequest.APT_Contract__c = apttusContract.Id;

		dealSupportRequest = (Deal_Support_Request__c) ApplicationTestDataFactory.setUnwritableFields(dealSupportRequest, new Map<String, Object>{
				'Organisation__r' => account,
				'APT_Contract__r' => apttusContract,
				'Opportunity__r' => opportunity
		});

		// =====================================
		// Stubbing
		// =====================================
		DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
		PickUpLocationSelector pickupLocationsSelector = (PickUpLocationSelector)MockUtility.mockSelector(PickUpLocationSelector.class);
		SubAccountRequestsSelector subAccountRequestsSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(dsrSelector.selectById(new Set<Id>{dealSupportRequest.Id}, new Set<Object>{
				DealSupportRequestsSelector.Options.WITH_CONTRACT,
				DealSupportRequestsSelector.Options.WITH_ORGANISATION,
				DealSupportRequestsSelector.Options.WITH_OPPORTUNITY,
				DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT,
				DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT,
				ApttusContractsSelector.Options.WITH_PROPOSAL
		})).thenReturn(new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest});

		MockUtility.Mocks.when(pickupLocationsSelector.selectById(new Set<Id>{opportunity.Primary_Pick_Up_Location__c})).thenReturn(new Map<Id, Pick_Up_Location__c>{pickupLocation.Id => pickupLocation});
		MockUtility.Mocks.when(subAccountRequestsSelector.selectByChargeAcountRequestIdAndStatus(
				(Set<Id>)fflib_Match.anyObject(),
				(Set<String>)fflib_Match.anyObject(),
				(Set<Object>)fflib_Match.anyObject()
		)).thenReturn(new Map<Id, APT_Sub_Account__c>(subAccountRequests));

		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());

		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ProvisionSTBillingAccountsController.BillingAccountProvisioningDetails response = ProvisionSTBillingAccountsController.generateBillingAccountsProvisioningRequest(dealSupportRequest.Id);
		Test.stopTest();

		Assert.isNotNull(response, 'Expected a valid response with generated request payload and external onboarding request id, but got null.');
		Assert.isNotNull(response.externalOnboardingRequestId, 'Expected a valid external onboarding request id, but got null.');
		Assert.isNotNull(response.requestPayload, 'Expected the generated request payload, but got null.');

		// should have inserted a new external onboarding request
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)sobjectCapture.capture());
		List<SObject> inserted = (List<SObject>) sobjectCapture.getValue();
		Assert.areEqual(1, inserted.size(), 'Only one BAMExternalOnboardingRequest__c record is expected to be inserted, but inserted [' + inserted.size() + '] records.');
		Assert.areEqual(response.externalOnboardingRequestId, inserted[0].Id, 'Expected to insert the external onboarding request returned in the results');

		fflib_ArgumentCaptor sobjectUpdateCapture = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)sobjectUpdateCapture.capture());
		List<SObject> updated = (List<SObject>) sobjectUpdateCapture.getValue();
		Assert.areEqual(1, updated.size(), 'Only one BAMExternalOnboardingRequest__c record is expected to be updated, but updated [' + updated.size() + '] records.');
		Assert.areEqual(response.externalOnboardingRequestId, updated[0].id, 'Expected to update the external onboarding request returned in the results');
		Assert.isNotNull(updated[0].get(BAMExternalOnboardingRequest__c.Request_Payload__c), 'Expected the request payload to be updated with a valid payload.');
	}

	/**
	 * Test to ensure provisioning request is generated successfully when required pre-conditions are satisfied.
	 */
	@IsTest
	private static void testGenerateSubAccountsProvisioningRequest() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		// setup leader account and another follower under the leader
		List<Billing_Account__c> billingAccounts = ApplicationTestDataFactory.getBillingAccounts(2, account.Id, 'TEAM', true);
		Billing_Account__c leaderBillingAccount = billingAccounts[0];
		leaderBillingAccount.ABN__c = '11111111111';
		leaderBillingAccount.ACN__c = '111111111';
		Billing_Account__c parentBillingAccount = billingAccounts[1];
		parentBillingAccount.PAYER_ACCOUNT_ID__c = leaderBillingAccount.Id;

		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		// setup sub account requests.
		List<APT_Sub_Account__c> subAccountRequests = ApplicationTestDataFactory.getSubAccountRequest(4, 'test', true);
		for (APT_Sub_Account__c subAccountRequest: subAccountRequests) {
			subAccountRequest.SubAccountContact__c = primaryContact.Id;
			subAccountRequest.APT_Billing_Account__c = leaderBillingAccount.Id;
		}

		// subAccountRequests[0] is a 'offspring' where invoice is paid by the leader
		subAccountRequests[0].AccountType__c = ProvisionSTBillingAccountsController.INVOICE_PAID_BY_LEADER_ACCOUNT_TYPE;
		subAccountRequests[0] = (APT_Sub_Account__c) ApplicationTestDataFactory.setUnwritableFields(subAccountRequests[0], new Map<String, Object>{
				'APT_Billing_Account__r' => leaderBillingAccount,
				'SubAccountContact__r' => primaryContact
		});

		// subAccountRequests[1] is a 'offspring of other follower' where invoice is paid by another existing billing account
		subAccountRequests[1].AccountType__c = ProvisionSTBillingAccountsController.INVOICE_PAID_BY_OTHER_ACCOUNT_TYPE;
		subAccountRequests[1].ParentBillingAccount__c = parentBillingAccount.Id;
		subAccountRequests[1] = (APT_Sub_Account__c) ApplicationTestDataFactory.setUnwritableFields(subAccountRequests[1], new Map<String, Object>{
				'APT_Billing_Account__r' => leaderBillingAccount,
				'SubAccountContact__r' => primaryContact,
				'ParentBillingAccount__r' => parentBillingAccount
		});

		// subAccountRequests[3] is a 'follower' where it pays it's own invoices.
		subAccountRequests[2].AccountType__c = 'Follower';
		subAccountRequests[2] = (APT_Sub_Account__c) ApplicationTestDataFactory.setUnwritableFields(subAccountRequests[2], new Map<String, Object>{
				'APT_Billing_Account__r' => leaderBillingAccount,
				'SubAccountContact__r' => primaryContact
		});

		// subAccountRequests[4] is a 'offspring of other follower' where invoice is paid by another new billing account also included in this request payload.
		subAccountRequests[3].AccountType__c =  ProvisionSTBillingAccountsController.INVOICE_PAID_BY_OTHER_ACCOUNT_TYPE;
		subAccountRequests[3].ParentAccountRequest__c =  subAccountRequests[2].Id;
		subAccountRequests[3] = (APT_Sub_Account__c) ApplicationTestDataFactory.setUnwritableFields(subAccountRequests[3], new Map<String, Object>{
				'APT_Billing_Account__r' => leaderBillingAccount,
				'SubAccountContact__r' => primaryContact,
				'ParentAccountRequest__r' => subAccountRequests[2]
		});

		// =====================================
		// Stubbing
		// =====================================
		SubAccountRequestsSelector subAccountRequestsSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(subAccountRequestsSelector.selectByIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, APT_Sub_Account__c>(subAccountRequests));
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ProvisionSTBillingAccountsController.BillingAccountProvisioningDetails response = ProvisionSTBillingAccountsController.generateSubAccountsProvisioningRequest(leaderBillingAccount.Id, new List<Id>{subAccountRequests[0].Id, subAccountRequests[1].Id, subAccountRequests[2].Id, subAccountRequests[3].Id});
		Test.stopTest();

		Assert.isNotNull(response, 'Expected a valid response with generated request payload and external onboarding request id, but got null.');
		Assert.isNotNull(response.externalOnboardingRequestId, 'Expected a valid external onboarding request id, but got null.');
		Assert.isNotNull(response.requestPayload, 'Expected the generated request payload, but got null.');

		Assert.isInstanceOfType(response.requestPayload, BillingAccountWrapperForTeams.class, 'Generated request payload is not valid for Star Track sub account provisioning');
		BillingAccountWrapperForTeams requestPayload = (BillingAccountWrapperForTeams) response.requestPayload;
		Assert.areEqual(response.externalOnboardingRequestId, requestPayload.transactionId, 'Request payload \'transactionId\' must be set to BAMExternalOnboardingRequest__c Id.');
		Assert.areEqual('TEAM', requestPayload.targetSystem, 'Request payload \'targetSystem\' must be set to \'TEAM\'.');
		Assert.areEqual(leaderBillingAccount.ABN__c, requestPayload.team.organisations.abn, 'Request payload \'team.organisations.abn\' must be set to leader billing account\'s ABN.');
		Assert.areEqual(leaderBillingAccount.ACN__c, requestPayload.team.organisations.acn, 'Request payload \'team.organisations.acn\' must be set to leader billing account\'s ACN.');
		Assert.areEqual(leaderBillingAccount.LEGACY_ID__c, requestPayload.team.organisations.billingAccountNo, 'Request payload \'team.organisations.billingAccountNo\' must be set to leader billing account\'s LEGACY_ID__c.');
		Assert.areEqual(subAccountRequests.size(), requestPayload.team.followerOffspringList.size(), 'Request payload does not include details of all sub account requests passed in.');
		for (BillingAccountWrapperForTeams.StarTrackSubAccount subAccountRequestPayload: requestPayload.team.followerOffspringList) {
			if (subAccountRequestPayload.followerOffspringRequestId == subAccountRequests[0].Id) {
				// invoice paid by leader
				Assert.areEqual(leaderBillingAccount.LEGACY_ID__c, subAccountRequestPayload.parentBillingAccountNo);
				Assert.isNull(subAccountRequestPayload.parentObjectId);
			} else if (subAccountRequestPayload.followerOffspringRequestId == subAccountRequests[1].Id) {
				// invoice paid by other existing billing account
				Assert.areEqual(parentBillingAccount.LEGACY_ID__c, subAccountRequestPayload.parentBillingAccountNo);
				Assert.isNull(subAccountRequestPayload.parentObjectId);
			} else if (subAccountRequestPayload.followerOffspringRequestId == subAccountRequests[2].Id) {
				// pays own invoices
				Assert.isNull(subAccountRequestPayload.parentBillingAccountNo);
				Assert.isNull(subAccountRequestPayload.parentObjectId);
			} else {
				// invoice paid by another new billing account in same request
				Assert.isNull(subAccountRequestPayload.parentBillingAccountNo);
				Assert.areEqual(subAccountRequests[2].Id, subAccountRequestPayload.parentObjectId);
			}
		}

		// should have inserted a new external onboarding request
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)sobjectCapture.capture());
		List<SObject> inserted = (List<SObject>) sobjectCapture.getValue();
		Assert.areEqual(1, inserted.size(), 'Only one BAMExternalOnboardingRequest__c record is expected to be inserted, but inserted [' + inserted.size() + '] records.');
		Assert.areEqual(response.externalOnboardingRequestId, inserted[0].Id, 'Expected to insert the external onboarding request returned in the results');

		fflib_ArgumentCaptor sobjectUpdateCapture = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)sobjectUpdateCapture.capture());
		List<SObject> updated = (List<SObject>) sobjectUpdateCapture.getValue();
		Assert.areEqual(1, updated.size(), 'Only one BAMExternalOnboardingRequest__c record is expected to be updated, but updated [' + inserted.size() + '] records.');
		Assert.areEqual(response.externalOnboardingRequestId, updated[0].id, 'Expected to update the external onboarding request returned in the results');
		Assert.isNotNull(updated[0].get(BAMExternalOnboardingRequest__c.Request_Payload__c), 'Expected the request payload to be updated with a valid payload.');
	}

	/**
	 * Ensure continuation state is set with the context information on submiting provisioning request
	 */
	@IsTest
	private static void testContinuationStateIsPopulatedOnSubmittingProvisioningRequest() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, organisation.Id, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunity.Id, organisation.Id, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRequest = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1, dealSupportRequest.Id, String.valueOf(Deal_Support_Request__c.SObjectType), true)[0];

		BillingAccountWrapperForTeams provisioningRequest = new BillingAccountWrapperForTeams(dealSupportRequest.Id, 'testprocesstype');

		// =====================================
		// Stubbing
		// =====================================
		BillingAccountService mockBillingAccountService = (BillingAccountService)MockUtility.mockUtility(BillingAccountService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockBillingAccountService.getContinuation(fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.eqString('Salesforce'))).thenReturn(new Continuation(120));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// Invoke the continuation
		Continuation cont = (Continuation)ProvisionSTBillingAccountsController.submitProvisioningRequest(provisioningRequest, externalOnboardingRequest.Id);

		Test.stopTest();

		Assert.isNotNull(cont, 'Valid continuation object is expected when attempting to submit provisioning request.');
		Assert.isNotNull(ProvisionSTBillingAccountsController.continuationState, 'Continuation object should contain valid state information to continue with processing the call back response, but state information was null');
		Assert.isInstanceOfType(ProvisionSTBillingAccountsController.continuationState, ProvisionSTBillingAccountsController.AsyncExecutionContext.class, 'Continuation state returned is not of the expected type.');
		ProvisionSTBillingAccountsController.AsyncExecutionContext context = (ProvisionSTBillingAccountsController.AsyncExecutionContext)ProvisionSTBillingAccountsController.continuationState;
		Assert.areEqual(dealSupportRequest.Id, context.requestObjId, '\'requestObjectId\' must be set to DSR record Id from provisioning request payload.');
		Assert.areEqual(provisioningRequest.processType, context.processType, '\'processType\' must be set to  processType set in provisioning request payload.');
		Assert.areEqual(externalOnboardingRequest.Id, context.onboardingRequestId, '\'onboardingRequestId\' must be set to external onboarding request id passed into submit method.');
	}

	/**
	 * Test to ensure status updates are done on DSR, External Onboarding Request and APT_Charge_Account__c on receiving a
	 * successful acknowledgement from external service
	 */
	@IsTest
	private static void testSubmitProvisioningRequestSuccessResponse() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, organisation.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunity.Id, organisation.Id, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRequest = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1, dealSupportRequest.Id, String.valueOf(Deal_Support_Request__c.SObjectType), true)[0];

		BillingAccountWrapperForTeams provisioningRequest = new BillingAccountWrapperForTeams(dealSupportRequest.Id, ProvisionSTBillingAccountsController.DSR_FLOW_PROCESS_TYPE);
		provisioningRequest.team.organisations = new BillingAccountWrapperForTeams.Organisations();
		provisioningRequest.team.organisations.leaderAccountRequestId = chargeAccountRequest.Id;

		// =====================================
		// Stubbing
		// =====================================
		BillingAccountService mockBillingAccountService = (BillingAccountService)MockUtility.mockUtility(BillingAccountService.class);
		ApplicationDatabase mockDatabase = (ApplicationDatabase)MockUtility.mockDatabase();

		// set up our responses
		HttpResponse mockHttpResponse = new HttpResponse();
		mockHttpResponse.setStatusCode(202);
		Test.setContinuationResponse('reqlabel', mockHttpResponse);

		BillingAccountService.Response mockResponse = new BillingAccountService.Response(202, 'testresponse');
		mockResponse.isSuccess = true;

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockBillingAccountService.getContinuation(fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.eqString('Salesforce'))).thenReturn(new Continuation(120));
		MockUtility.Mocks.when(mockBillingAccountService.parseResponse((HttpResponse)fflib_Match.eq(mockHttpResponse))).thenReturn(mockResponse);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate(((List<SObject>)fflib_Match.anyObject()), fflib_Match.eqBoolean(false))).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// invoke the continuation
		Continuation cont = (Continuation)ProvisionSTBillingAccountsController.submitProvisioningRequest(provisioningRequest, externalOnboardingRequest.Id);
		BillingAccountService.Response response = ProvisionSTBillingAccountsController.processBillingAccountProvisioningCallback(new List<String>{'reqlabel'}, ProvisionSTBillingAccountsController.continuationState);

		Test.stopTest();

		Assert.areEqual(response, mockResponse, 'Ensure the response received from BillingAccountService is returned by the controller');

		fflib_ArgumentCaptor sobjectUpdateCapture = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)sobjectUpdateCapture.capture(), fflib_Match.eqBoolean(false));
		List<SObject> updatedRecords = (List<SObject>) sobjectUpdateCapture.getValue();
		Assert.areEqual(3, updatedRecords.size(), 'DSR, Charge Account Request and External Onboarding Request records are expected to be updated, but updated [' + updatedRecords.size() + '] records.');

		for (SObject updated: updatedRecords) {
			if (updated instanceof BAMExternalOnboardingRequest__c) {
				Assert.areEqual('Pending', updated.get(BAMExternalOnboardingRequest__c.Status__c), 'External Onboarding Request status should be set to \'Pending\' on receiving successful acknowledgement');
				Assert.areEqual(updated.get(BAMExternalOnboardingRequest__c.Response_Payload__c), mockResponse.responseBody, 'External Onboarding Request \'Response_Payload__c\' must be set to body of the http response received');
				Assert.isFalse(updated.isSet(BAMExternalOnboardingRequest__c.Error__c), 'External Onboarding Request \'Error__c\' should not be set on receiving successful acknowledgement');
			}

			if (updated instanceof APT_Charge_Account__c) {
				Assert.areEqual(updated.get(APT_Charge_Account__c.Status__c), 'New', 'Charge Account Request \'Status__c\' must be set to \'New\' on receiving successful acknowledgement.');
			}

			if (updated instanceof Deal_Support_Request__c) {
				Assert.areEqual(updated.get(Deal_Support_Request__c.Integration_Status__c), 'Requested', 'DSR \'Integration_Status__c\' must be set to \'Requested\' on receiving successful acknowledgement.');
				Assert.isFalse(updated.isSet(Deal_Support_Request__c.Integration_Status_Description__c), 'DSR \'Integration_Status_Description__c\' should not be set on receiving successful acknowledgement');
				Assert.areEqual(updated.get(Deal_Support_Request__c.Integration_Transaction_Id__c), externalOnboardingRequest.Id, 'DSR \'Integration_Transaction_Id__c\' must be set to External Onboarding Request Id on receiving successful acknowledgement.');
			}
		}
	}

	/**
	 * Test to ensure status updates are done on DSR, Charge Account Request and External Onboarding Request on receiving an error from external service
	 */
	@IsTest
	private static void testSubmitProvisioningRequestErrorResponse() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, organisation.Id, true)[0];
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1, true)[0];
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunity.Id, organisation.Id, true)[0];
		BAMExternalOnboardingRequest__c externalOnboardingRequest = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1, dealSupportRequest.Id, String.valueOf(Deal_Support_Request__c.SObjectType), true)[0];

		BillingAccountWrapperForTeams provisioningRequest = new BillingAccountWrapperForTeams(dealSupportRequest.Id, ProvisionSTBillingAccountsController.DSR_FLOW_PROCESS_TYPE);
		provisioningRequest.team.organisations = new BillingAccountWrapperForTeams.Organisations();
		provisioningRequest.team.organisations.leaderAccountRequestId = chargeAccountRequest.Id;

		// =====================================
		// Stubbing
		// =====================================
		BillingAccountService mockBillingAccountService = (BillingAccountService)MockUtility.mockUtility(BillingAccountService.class);
		ApplicationDatabase mockDatabase = (ApplicationDatabase)MockUtility.mockDatabase();

		// set up our responses
		HttpResponse mockHttpResponse = new HttpResponse();
		mockHttpResponse.setStatusCode(400);
		Test.setContinuationResponse('reqlabel', mockHttpResponse);

		BillingAccountService.Response mockResponse = new BillingAccountService.Response(400, 'testresponse');
		mockResponse.errors.add('test error response');
		mockResponse.isSuccess = false;

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockBillingAccountService.getContinuation(fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.eqString('Salesforce'))).thenReturn(new Continuation(120));
		MockUtility.Mocks.when(mockBillingAccountService.parseResponse((HttpResponse)fflib_Match.eq(mockHttpResponse))).thenReturn(mockResponse);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate(((List<SObject>)fflib_Match.anyObject()), fflib_Match.eqBoolean(false))).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// invoke the continuation
		Continuation cont = (Continuation)ProvisionSTBillingAccountsController.submitProvisioningRequest(provisioningRequest, externalOnboardingRequest.Id);
		BillingAccountService.Response response = ProvisionSTBillingAccountsController.processBillingAccountProvisioningCallback(new List<String>{'reqlabel'}, ProvisionSTBillingAccountsController.continuationState);

		Test.stopTest();

		Assert.areEqual(response, mockResponse, 'Ensure the response received from BillingAccountService is returned by the controller');

		fflib_ArgumentCaptor sobjectUpdateCapture = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)sobjectUpdateCapture.capture(), fflib_Match.eqBoolean(false));
		List<SObject> updatedRecords = (List<SObject>) sobjectUpdateCapture.getValue();
		Assert.areEqual(3, updatedRecords.size(), 'DSR, Charge Account Request and External Onboarding Request records are expected to be updated, but updated [' + updatedRecords.size() + '] records.');

		for (SObject updated: updatedRecords) {
			if (updated instanceof BAMExternalOnboardingRequest__c) {
				Assert.areEqual(updated.get(BAMExternalOnboardingRequest__c.Status__c), 'Error', 'External Onboarding Request \'Status__c\' must be set to \'Error\' on receiving an error from external service.');
				Assert.areEqual(updated.get(BAMExternalOnboardingRequest__c.Response_Payload__c), mockResponse.responseBody, 'External Onboarding Request \'Response_Payload__c\' must be set to body of the http response received');
				Assert.areEqual(updated.get(BAMExternalOnboardingRequest__c.Error__c), mockResponse.getErrorMessage(), 'External Onboarding Request \'Error__c\' must be set to the error message');
			}

			if (updated instanceof APT_Charge_Account__c) {
				Assert.areEqual(updated.get(APT_Charge_Account__c.Status__c), 'Error', 'Charge Account Request \'Status__c\' must be set to \'Error\' on receiving an error from external service.');
			}

			if (updated instanceof Deal_Support_Request__c) {
				Assert.areEqual(updated.get(Deal_Support_Request__c.Integration_Status__c), 'Error', 'DSR \'Integration_Status__c\' must be set to \'Error\' on receiving error.');
				Assert.areEqual(updated.get(Deal_Support_Request__c.Integration_Status_Description__c), mockResponse.getErrorMessage(), 'DSR \'Integration_Status_Description__c\' must be set to error message from external service.');
				Assert.areEqual(updated.get(Deal_Support_Request__c.Integration_Transaction_Id__c), externalOnboardingRequest.Id, 'DSR \'Integration_Transaction_Id__c\' must be set to External Onboarding Request Id on receiving response from external system.');
			}
		}
	}

	/**
	 * Test to ensure status updates are done on External Onboarding Request and Sub Account Request records on receiving
	 * successful acknowledgement from external service for a sub accounts provisioning request (i.e. Billing Accounts flow)
	 */
	@IsTest
	private static void testSubmitSubAccountsProvisioningRequestSuccessResponse() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Billing_Account__c leaderBillingAccount = ApplicationTestDataFactory.getBillingAccounts(1, organisation.Id, 'TEAM', true)[0];
		List<APT_Sub_Account__c> subAccountRequests = ApplicationTestDataFactory.getSubAccountRequest(2, 'subaccountrequests', true);
		BAMExternalOnboardingRequest__c externalOnboardingRequest = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1, leaderBillingAccount.Id, String.valueOf(Billing_Account__c.SObjectType), true)[0];

		BillingAccountWrapperForTeams provisioningRequest = new BillingAccountWrapperForTeams(leaderBillingAccount.Id, ProvisionSTBillingAccountsController.BILLING_ACCOUNT_FLOW_PROCESS_TYPE);
		provisioningRequest.team.organisations = new BillingAccountWrapperForTeams.Organisations();
		provisioningRequest.team.followerOffspringList = new List<BillingAccountWrapperForTeams.StarTrackSubAccount>();
		for (APT_Sub_Account__c subAccountRequest: subAccountRequests) {
			provisioningRequest.team.followerOffspringList.add(new BillingAccountWrapperForTeams.StarTrackSubAccount(subAccountRequest.Id, subAccountRequest.Name));
		}

		// =====================================
		// Stubbing
		// =====================================
		BillingAccountService mockBillingAccountService = (BillingAccountService)MockUtility.mockUtility(BillingAccountService.class);
		ApplicationDatabase mockDatabase = (ApplicationDatabase)MockUtility.mockDatabase();

		// set up our responses
		HttpResponse mockHttpResponse = new HttpResponse();
		mockHttpResponse.setStatusCode(202);
		Test.setContinuationResponse('reqlabel', mockHttpResponse);

		BillingAccountService.Response mockResponse = new BillingAccountService.Response(202, 'testresponse');
		mockResponse.isSuccess = true;

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockBillingAccountService.getContinuation(fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.eqString('Salesforce'))).thenReturn(new Continuation(120));
		MockUtility.Mocks.when(mockBillingAccountService.parseResponse((HttpResponse)fflib_Match.eq(mockHttpResponse))).thenReturn(mockResponse);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate(((List<SObject>)fflib_Match.anyObject()), fflib_Match.eqBoolean(false))).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// invoke the continuation
		Continuation cont = (Continuation)ProvisionSTBillingAccountsController.submitProvisioningRequest(provisioningRequest, externalOnboardingRequest.Id);
		BillingAccountService.Response response = ProvisionSTBillingAccountsController.processBillingAccountProvisioningCallback(new List<String>{'reqlabel'}, ProvisionSTBillingAccountsController.continuationState);

		Test.stopTest();

		Assert.areEqual(response, mockResponse, 'Ensure the response received from BillingAccountService is returned by the controller');

		fflib_ArgumentCaptor sobjectUpdateCapture = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)sobjectUpdateCapture.capture(), fflib_Match.eqBoolean(false));
		List<SObject> updatedRecords = (List<SObject>) sobjectUpdateCapture.getValue();
		Assert.areEqual(3, updatedRecords.size(), 'External Onboarding Request and 2 Sub Account Request records are expected to be updated, but updated [' + updatedRecords.size() + '] records.');

		for (SObject updated: updatedRecords) {
			if (updated instanceof BAMExternalOnboardingRequest__c) {
				Assert.areEqual('Pending', updated.get(BAMExternalOnboardingRequest__c.Status__c), 'External Onboarding Request status should be set to \'Pending\' on receiving successful acknowledgement');
				Assert.areEqual(updated.get(BAMExternalOnboardingRequest__c.Response_Payload__c), mockResponse.responseBody, 'External Onboarding Request \'Response_Payload__c\' must be set to body of the http response received');
				Assert.isFalse(updated.isSet(BAMExternalOnboardingRequest__c.Error__c), 'External Onboarding Request \'Error__c\' should not be set on receiving successful acknowledgement');
			} else if (updated instanceof APT_Sub_Account__c) {
				Assert.areEqual('Submitted', updated.get(APT_Sub_Account__c.APT_Sub_Account_Request_Status__c), 'Sub Account Request status should be set to \'Submitted\' on receiving successful acknowledgement');
			}
		}
	}

	private static Apttus__APTS_Agreement__c getApttusContractWithRelatedContactAndProposal(Contact primaryContact, Id opportunityId, Id chargeAccountRequestId) {
		APT_Credit_Assessment__c creditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequestId, true)[0];
		creditAssessment.StarTrack_Proposed_for_New_Account__c = 25000;
		creditAssessment.APT_Credit_Assessment_Status__c = ProvisionSTBillingAccountsController.VALID_CREDIT_ASSESSMENT_STATUS.iterator().next();

		Apttus_Proposal__Proposal__c apttusProposal = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
		apttusProposal.APT_Minimum_Monthly_Spend__c = 2000;

		Apttus__APTS_Agreement__c apttusContract = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityId, true)[0];
		apttusContract.Apttus_QPComply__RelatedProposalId__c = apttusProposal.Id;
		apttusContract.Term__c = 'Open Ended';

		apttusProposal = (Apttus_Proposal__Proposal__c) ApplicationTestDataFactory.setUnwritableFields(apttusProposal, new Map<String, Object>{
				'APT_Credit_Assessment__r' => creditAssessment
		});

		apttusContract = (Apttus__APTS_Agreement__c) ApplicationTestDataFactory.setUnwritableFields(apttusContract, new Map<String, Object>{
				'Apttus__Primary_Contact__r' => primaryContact,
				'Apttus_QPComply__RelatedProposalId__r' => apttusProposal
		});

		return apttusContract;
	}

	private static Pick_Up_Location__c getPickupLocation(Id opportunityId) {

		Customer_Scoping_Questionnaire__c csq = ApplicationTestDataFactorySales.getCustomerScopingQuestionnaires(1, opportunityId, true)[0];

		Pick_Up_Location__c pickupLocation = ApplicationTestDataFactorySales.getPickUpLocations(1, csq.Id, true)[0];
		pickupLocation.Address__c = 'test street';
		pickupLocation.Suburb__c = 'test';
		pickupLocation.State__c = 'VIC';
		pickupLocation.Postcode__c = '3000';

		return pickupLocation;
	}

}