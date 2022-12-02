/**
 * @description
 * Test class for SalesRecordSharingService
 * @author Ranjeewa Silva
 * @group Tests
 * @domain Sales
 * @changelog
 * 2022-12-02 - Ranjeewa Silva - Created
 */
@IsTest
private class SalesRecordSharingService_Test {

	/**
	 * Test to ensure an exception (SalesRecordSharingException) is thrown when custom metadata is not configured for the SObjectType passed in.
	 */
	@IsTest
	static void testGetSharingConfigurationThrowsExceptionForSobjectTypesNotConfiguredInMetadata() {
		// =====================================
		// Data Preparation
		// =====================================
		// None

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			SalesRecordSharingService.getInstance().getSharingConfiguration(Case.SObjectType);
			System.assert(false, 'Expected to throw an exception when SObjectType is not configured in custom metadata, but no exception thrown.');
		} catch (SalesRecordSharingService.SalesRecordSharingException ex) {
			// expected
		} catch (Exception ex) {
			System.assert(false, 'Expected to throw SalesRecordSharingException, but got ' + ex.getTypeName());
		}

		Test.stopTest();
	}

	/**
	 * Test to ensure an exception (SalesRecordSharingException) is thrown when null is passed as SObjectType.
	 */
	@IsTest
	static void testGetSharingConfigurationThrowsExceptionForPassingNullAsSObjectType() {
		// =====================================
		// Data Preparation
		// =====================================
		// None

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			SObjectType s = null;
			SalesRecordSharingService.getInstance().getSharingConfiguration(s);
			System.assert(false, 'Expected to throw an exception when invalid SObjectType is passed, but no exception thrown.');
		} catch (SalesRecordSharingService.SalesRecordSharingException ex) {
			// expected
		}  catch (Exception ex) {
			System.assert(false, 'Expected to throw SalesRecordSharingException, but got ' + ex.getTypeName());
		}

		Test.stopTest();
	}

	/**
	 * Test to ensure an exception (SalesRecordSharingException) is thrown if at least one public group configured in
	 * custom metadata does not exist in the org.
	 */
	@IsTest
	static void testGetSharingConfigurationThrowsExceptionWhenConfiguredPublicGroupsNotPresent() {
		// =====================================
		// Data Preparation
		// =====================================
		SalesSharingObjectMapping__mdt metadata = SalesRecordSharingService.salesSharingMetadata.get(String.valueOf(APR__c.SObjectType));
		metadata.SalesSharingGroupMappings__r[0].GroupName__c = 'InvalidGroup_01234567890';

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			SalesRecordSharingService.getInstance().getSharingConfiguration(APR__c.getSObjectType());
			System.assert(false, 'Expected to throw an exception when invalid public group is configured in custom metadata; but not thrown.');
		} catch (SalesRecordSharingService.SalesRecordSharingException ex) {
			// expected
		}  catch (Exception ex) {
			System.assert(false, 'Expected to throw SalesRecordSharingException, but got ' + ex.getTypeName());
		}

		Test.stopTest();
	}

	/**
	 * Test to ensure sharing configuration mapping is returned for SObjectTypes where metadata configuration is available.
	 */
	@IsTest
	static void testGetSharingConfiguration() {
		// =====================================
		// Data Preparation
		// =====================================

		// inject public group ids in service class so that the test doesn't depend on public group data in the org
		injectMockPublicGroupIdsInService();

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesRecordSharingService.SalesSharingObjectMapping mapping = SalesRecordSharingService.getInstance().getSharingConfiguration(APR__C.getSObjectType());

		Test.stopTest();

		System.assertNotEquals(null, mapping, 'Expected a valid sharing configuration mapping, but got null instead.');
		System.assertEquals(APR__c.SObjectType, mapping.objectType, 'SObjectType returned in sharing configuration is incorrect');
		System.assertEquals(APR__c.Legal_Entity_Name_LookUp__c, mapping.lookupField, 'Account lookup field returned in sharing configuration is incorrect');
		System.assertEquals('Legal_Entity_Name_LookUp__r', mapping.lookupRelationshipName, 'Account lookup relationship (__r) field returned in sharing configuration is incorrect');
		System.assertNotEquals(null, mapping.sharingReason, 'Sharing reason must be populated');
		System.assertEquals('APR__Share', mapping.shareObjectApiName, 'Share object AP Name must be populated');
		System.assertNotEquals(null, mapping.groupMappings, 'sharing group mappings must be populated');
		Integer numberOfGroupsConfigured = SalesRecordSharingService.salesSharingMetadata.get(String.valueOf(APR__c.getSObjectType())).SalesSharingGroupMappings__r.size();
		System.assertEquals(numberOfGroupsConfigured, mapping.groupMappings.size(), 'Three sharing groups are expected for APR__c, but got ' + mapping.groupMappings.size());
	}

	/**
	 * Test to ensure parent accounts are queried only for those sobjects where:
	 *  - parent account reference is not populated on sobject but parent account id is set (i.e. lookup__c != null AND lookup__r == null).
	 *  - parent account reference is populated, however, the SalesTeamType__c field is not set on parent account.
	 */
	@IsTest
	static void testParentAccountQueryingInGetSalesTeamTypeMapping() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(3, true);

		parentAccounts[0].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;
		parentAccounts[1].SalesTeamType__c = null;
		parentAccounts[2].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_INTERMEDIARY;

		List<APR__c> aprs = ApplicationTestDataFactory.getAPRs(4, null, null, true);
		aprs[0].Legal_Entity_Name_LookUp__c = parentAccounts[0].Id;
		aprs[1].Legal_Entity_Name_LookUp__c = parentAccounts[1].Id;
		aprs[2].Legal_Entity_Name_LookUp__c = parentAccounts[2].Id;
		aprs[3].Legal_Entity_Name_LookUp__c = null;

		aprs[0] = (APR__c) ApplicationTestDataFactory.setUnwritableFields(aprs[0], new Map<String, Object>{'Legal_Entity_Name_LookUp__r' => parentAccounts[0]});
		aprs[1] = (APR__c) ApplicationTestDataFactory.setUnwritableFields(aprs[1], new Map<String, Object>{'Legal_Entity_Name_LookUp__r' => parentAccounts[1]});

		SalesRecordSharingService.SalesSharingObjectMapping sharingObjectMapping = new SalesRecordSharingService.SalesSharingObjectMapping(APR__c.SObjectType, APR__c.Legal_Entity_Name_LookUp__c, 'Legal_Entity_Name_LookUp__r','Test');

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector mockAccountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{parentAccounts[2].Id => parentAccounts[2]});

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id, String> salesTeamTypeMapping = SalesRecordSharingService.getInstance().getSalesTeamTypeMapping(new Map<Id, APR__c>(aprs), sharingObjectMapping);

		Test.stopTest();

		// verify account selector was called only for the APR whose parent account Id is populated but the account reference (Legal_Entity_Name_LookUp__r)
		// is not populated in SObject
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(Set<Id>.class);
		((AccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)sobjectCapture.capture());
		Set<Id> parentAccountIds = (Set<Id>) sobjectCapture.getValue();

		System.assertEquals(1, parentAccountIds.size(), 'Parent accounts must be queried only when Account relationship (\'Legal_Entity_Name_LookUp__r\') is not populated in sobject.');
		System.assert(parentAccountIds.contains(aprs[2].Legal_Entity_Name_LookUp__c), 'Parent accounts must be queried only when Account relationship (\'Legal_Entity_Name_LookUp__r\') is not populated in sobject.');

		System.assertNotEquals(null, salesTeamTypeMapping, 'Expected a valid sales team type mapping for sobjects passed in, but got null');
		System.assertEquals(3, salesTeamTypeMapping.size(), 'Expected sales team type mapping for all sobjects where parent account id is populated');
		System.assertEquals(parentAccounts[0].SalesTeamType__c, salesTeamTypeMapping.get(aprs[0].Id), 'Sales Team type mapping for sobject should match sales team type on parent account');
		System.assertEquals(parentAccounts[1].SalesTeamType__c, salesTeamTypeMapping.get(aprs[1].Id), 'Sales Team type mapping for sobject should match sales team type on parent account');
		System.assertEquals(parentAccounts[2].SalesTeamType__c, salesTeamTypeMapping.get(aprs[2].Id), 'Sales Team type mapping for sobject should match sales team type on parent account');
	}

	/**
	 * Test to ensure record details are logged if Sales Team Type on parent account is not set. This scenario will
	 * only occur if picklist dependencies are not configured properly on Account.SalesTeamType__c.
	 */
	@IsTest
	static void testShareNewRecordsWhenSalesTeamTypeOnParentAccountIsNotSet() {
		// =====================================
		// Data Preparation
		// =====================================

		// inject public group ids in service class so that the test doesn't depend on public group data in the org
		injectMockPublicGroupIdsInService();

		Account parentAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		// set SalesTeamType__c to null.
		parentAccount.SalesTeamType__c = null;

		APR__c apr = ApplicationTestDataFactory.getAPRs(1, null, null, true)[0];
		apr = (APR__c) ApplicationTestDataFactory.setUnwritableFields(apr, new Map<String, Object>{'Legal_Entity_Name_LookUp__r' => parentAccount});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesRecordSharingService.getInstance().shareRecords(APR__C.getSObjectType(), new Map<Id, APR__c>{apr.Id => apr}, false, mockUow);

		Test.stopTest();

		// verify no new share records are registered with unit of work.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerNew((List<SObject>)fflib_Match.anyObject(), (Boolean)fflib_Match.eqBoolean(false), (String)fflib_Match.anyObject());

		// verify excluded records are logged
		// make sure no exceptions were thrown
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 1)).logMessage((List<String>)fflib_Match.anyObject(), (List<String>)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
	}

	/**
	 * Test to ensure record details are logged if sharing groups are not configured in custom metadata for Sales Team
	 * Type on parent account.
	 */
	@IsTest
	static void testShareNewRecordsWhenSharingGroupsNotConfiguredForSalesTeamType() {
		// =====================================
		// Data Preparation
		// =====================================

		// inject public group ids in service class so that the test doesn't depend on public group data in the org
		injectMockPublicGroupIdsInService();

		Account parentAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		// set SalesTeamType__c to something unknown.
		parentAccount.SalesTeamType__c = 'NotConfigured';

		APR__c apr = ApplicationTestDataFactory.getAPRs(1, null, null, true)[0];
		apr = (APR__c) ApplicationTestDataFactory.setUnwritableFields(apr, new Map<String, Object>{'Legal_Entity_Name_LookUp__r' => parentAccount});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesRecordSharingService.getInstance().shareRecords(APR__C.getSObjectType(), new Map<Id, APR__c>{apr.Id => apr}, false, mockUow);

		Test.stopTest();

		// verify no new share records are registered with unit of work.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerNew((List<SObject>)fflib_Match.anyObject(), (Boolean)fflib_Match.eqBoolean(false), (String)fflib_Match.anyObject());

		// verify excluded records are logged
		// make sure no exceptions were thrown
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 1)).logMessage((List<String>)fflib_Match.anyObject(), (List<String>)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
	}

	/**
	 * Test to ensure new share records are created as expected when calling service class with recalculate=false
	 */
	@IsTest
	static void testShareNewRecords() {
		// =====================================
		// Data Preparation
		// =====================================

		// inject public group ids in service class so that the test doesn't depend on public group data in the org
		injectMockPublicGroupIdsInService();

		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(3, true);
		parentAccounts[0].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;
		parentAccounts[1].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_INTERMEDIARY;
		parentAccounts[2].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_HOLDING;

		List<APR__c> aprs = ApplicationTestDataFactory.getAPRs(3, null, null, true);
		aprs[0].Legal_Entity_Name_LookUp__c = parentAccounts[0].Id;
		aprs[1].Legal_Entity_Name_LookUp__c = parentAccounts[1].Id;
		aprs[2].Legal_Entity_Name_LookUp__c = parentAccounts[2].Id;

		aprs[0] = (APR__c) ApplicationTestDataFactory.setUnwritableFields(aprs[0], new Map<String, Object>{'Legal_Entity_Name_LookUp__r' => parentAccounts[0]});
		aprs[1] = (APR__c) ApplicationTestDataFactory.setUnwritableFields(aprs[1], new Map<String, Object>{'Legal_Entity_Name_LookUp__r' => parentAccounts[1]});
		aprs[2] = (APR__c) ApplicationTestDataFactory.setUnwritableFields(aprs[2], new Map<String, Object>{'Legal_Entity_Name_LookUp__r' => parentAccounts[2]});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUow.registerNew((SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesRecordSharingService.getInstance().shareRecords(APR__C.getSObjectType(), new Map<Id, APR__c>(aprs), false, mockUow);

		Test.stopTest();

		// verify new share records registered with unit of work are as expected
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<SObject>)sobjectCapture.capture(), (Boolean)fflib_Match.eqBoolean(false), (String)fflib_Match.anyObject());
		List<SObject> shares = (List<SObject>) sobjectCapture.getValue();

		System.assertEquals(3, shares.size(), 'Expected to create three share records for the 3 sobject records');

		Map<Id, APR__c> aprsMap = new Map<Id, APR__c>(aprs);
		SalesSharingObjectMapping__mdt metadata = SalesRecordSharingService.salesSharingMetadata.get(String.valueOf(APR__c.SObjectType));
		for (APR__Share share: (List<APR__Share>)shares) {
			System.assert(aprsMap.keySet().contains(share.ParentId), 'Unexpected share record created');
			System.assertEquals(metadata.SharingReasonName__c, share.RowCause, 'Incorrect sharing reason specified on share record');
		}
	}

	/**
	 * TODO
	 */
	@IsTest
	static void testRecalculateSharing() {
		// =====================================
		// Data Preparation
		// =====================================

		// inject public group ids in service class so that the test doesn't depend on public group data in the org
		injectMockPublicGroupIdsInService();

		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(1, true);
		parentAccounts[0].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;

		List<APR__c> aprs = ApplicationTestDataFactory.getAPRs(1, null, null, true);
		aprs[0].Legal_Entity_Name_LookUp__c = parentAccounts[0].Id;

		aprs[0] = (APR__c) ApplicationTestDataFactory.setUnwritableFields(aprs[0], new Map<String, Object>{'Legal_Entity_Name_LookUp__r' => parentAccounts[0]});

		List<Group> publicGroups = ApplicationTestDataFactory.getGroups(3, SalesRecordSharingService.PUBLIC_GROUP_TYPES_SUPPORTED.iterator().next(), true);
		SalesSharingObjectMapping__mdt metadata = SalesRecordSharingService.salesSharingMetadata.get(String.valueOf(APR__c.SObjectType));

		List<APR__Share> existingAPRShares = new List<APR__Share>();
		existingAPRShares.add(new APR__Share(ParentId=aprs[0].Id, UserOrGroupId=publicGroups[0].Id, AccessLevel='View', RowCause=metadata.SharingReasonName__c));

		// =====================================
		// Stubbing
		// =====================================
		SObjectSharesSelector mockSObjectSharesSelector = ((SObjectSharesSelector) MockUtility.mockSelector(SObjectSharesSelector.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSObjectSharesSelector.setShareSobjectType((SObjectType)fflib_Match.anyObject())).thenReturn(mockSObjectSharesSelector);
		MockUtility.Mocks.when(mockSObjectSharesSelector.selectByParentIdAndRowCause((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(existingAPRShares);
		MockUtility.Mocks.when(mockUow.registerNew((SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		((ApplicationUnitOfWork)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockUow)).registerDeleted((SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesRecordSharingService.getInstance().shareRecords(APR__C.getSObjectType(), new Map<Id, APR__c>(aprs), true, mockUow);

		Test.stopTest();

		// verify new share records registered with unit of work are as expected
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(SObject.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((SObject)sobjectCapture.capture(), (Boolean)fflib_Match.eqBoolean(false), (String)fflib_Match.anyObject());
		APR__Share share = (APR__Share) sobjectCapture.getValue();

		System.assertEquals(APR__Share.SObjectType, share.getSObjectType(), 'Expected to create three share records of type APR__Share');
		System.assertEquals(aprs[0].Id, share.ParentId, 'Unexpected share record created');
		System.assertEquals(metadata.SharingReasonName__c, share.RowCause, 'Incorrect sharing reason specified on share record');

		// verify shares deleted
		fflib_ArgumentCaptor deletedSObjectsCapture = fflib_ArgumentCaptor.forClass(SObject.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDeleted((SObject)deletedSObjectsCapture.capture(), (Boolean)fflib_Match.eqBoolean(false), (String)fflib_Match.anyObject());
		APR__Share deletedShare = (APR__Share) deletedSObjectsCapture.getValue();
		System.assertEquals(existingAPRShares[0].Id, deletedShare.Id, 'Expected to delete one existing share record for the sobject record');
	}

	/**
	 * Test to ensure new share records are created as expected when calling overloaded service method that also manage
	 * the unit of work on behalf of callers.
	 */
	@IsTest
	static void testShareNewRecordsWhenNoUnitOfWorkInstanceAvailable() {
		// =====================================
		// Data Preparation
		// =====================================

		// inject public group ids in service class so that the test doesn't depend on public group data in the org
		injectMockPublicGroupIdsInService();

		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(3, true);
		parentAccounts[0].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;
		parentAccounts[1].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_INTERMEDIARY;
		parentAccounts[2].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_HOLDING;

		List<APR__c> aprs = ApplicationTestDataFactory.getAPRs(3, null, null, true);
		aprs[0].Legal_Entity_Name_LookUp__c = parentAccounts[0].Id;
		aprs[1].Legal_Entity_Name_LookUp__c = parentAccounts[1].Id;
		aprs[2].Legal_Entity_Name_LookUp__c = parentAccounts[2].Id;

		aprs[0] = (APR__c) ApplicationTestDataFactory.setUnwritableFields(aprs[0], new Map<String, Object>{'Legal_Entity_Name_LookUp__r' => parentAccounts[0]});
		aprs[1] = (APR__c) ApplicationTestDataFactory.setUnwritableFields(aprs[1], new Map<String, Object>{'Legal_Entity_Name_LookUp__r' => parentAccounts[1]});
		aprs[2] = (APR__c) ApplicationTestDataFactory.setUnwritableFields(aprs[2], new Map<String, Object>{'Legal_Entity_Name_LookUp__r' => parentAccounts[2]});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUow.registerNew((SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesRecordSharingService.getInstance().shareRecords(APR__C.getSObjectType(), new Map<Id, APR__c>(aprs), false);

		Test.stopTest();

		// verify new share records registered with unit of work are as expected
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<SObject>)sobjectCapture.capture(), (Boolean)fflib_Match.eqBoolean(false), (String)fflib_Match.anyObject());
		List<SObject> shares = (List<SObject>) sobjectCapture.getValue();

		System.assertEquals(3, shares.size(), 'Expected to create three share records for the 3 sobject records');

		Map<Id, APR__c> aprsMap = new Map<Id, APR__c>(aprs);
		SalesSharingObjectMapping__mdt metadata = SalesRecordSharingService.salesSharingMetadata.get(String.valueOf(APR__c.SObjectType));
		for (APR__Share share: (List<APR__Share>)shares) {
			System.assert(aprsMap.keySet().contains(share.ParentId), 'Unexpected share record created');
			System.assertEquals(metadata.SharingReasonName__c, share.RowCause, 'Incorrect sharing reason specified on share record');
		}

		// verify unit of work is committed by the service
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).commitWork();
	}

//	@IsTest
//	static void testShareNewRecordsEndToEndIntegration() {
//
//		// =====================================
//		// Data Preparation
//		// =====================================
//		MockUtility.disableTriggerExecution();
//
//		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(3, false);
//		parentAccounts[0].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;
//		parentAccounts[0].Sales_Segment__c = 'Enterprise & Strategic NSW 1';
//		parentAccounts[0].LEGACY_ID__c = '60000000';
//
//		parentAccounts[1].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_INTERMEDIARY;
//		parentAccounts[1].Sales_Segment__c = 'Intermediaries';
//		parentAccounts[1].LEGACY_ID__c = '60000002';
//
//		parentAccounts[2].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_HOLDING;
//		parentAccounts[2].Sales_Segment__c = 'Holding Sales Team';
//		parentAccounts[2].LEGACY_ID__c = '60000003';
//
//		insert(parentAccounts);
//
//		List<Billing_Account__c> billingAccounts =  new List<Billing_Account__c>();
//		for (Account parentAccount: parentAccounts) {
//			billingAccounts.add(ApplicationTestDataFactory.getBillingAccounts(1, parentAccount.Id, 'SAP CRM', false)[0]);
//		}
//		insert (billingAccounts);
//
//		List<APR__c> aprs = new List<APR__c>();
//		for (Billing_Account__c billingAccount: billingAccounts) {
//			APR__c apr = ApplicationTestDataFactory.getAPRs(1, billingAccount.Id, null, false)[0];
//			apr.Legal_Entity_Name_LookUp__c = billingAccount.Organisation__c;
//			aprs.add(apr);
//		}
//		insert(aprs);
//
//		// =====================================
//		// Stubbing
//		// =====================================
//		// None
//
//		// =====================================
//		// Testing
//		// =====================================
//		Test.startTest();
//
//		SalesRecordSharingService.getInstance().shareRecords(APR__C.getSObjectType(), new Map<Id, APR__c>(aprs), false);
//
//		Test.stopTest();
//
//		List<APR__Share> shares = [Select Id, ParentId, UserOrGroupId, AccessLevel, RowCause from APR__Share Where RowCause = 'Sales_Team_Sharing__c'];
//		System.assertEquals(3, shares.size());
//		for (APR__Share share: shares) {
//			System.assertEquals('Edit', share.AccessLevel);
//			System.assertNotEquals(null, share.ParentId);
//			System.assertNotEquals(null, share.UserOrGroupId);
//		}
//
//	}

	private static void injectMockPublicGroupIdsInService() {
		SalesSharingObjectMapping__mdt aprMetadata = SalesRecordSharingService.salesSharingMetadata.get(String.valueOf(APR__c.getSObjectType()));
		List<Group> groups = ApplicationTestDataFactory.getGroups(aprMetadata.SalesSharingGroupMappings__r.size(), SalesRecordSharingService.PUBLIC_GROUP_TYPES_SUPPORTED.iterator().next(), true);
		for (Integer i=0; i < aprMetadata.SalesSharingGroupMappings__r.size(); i++) {
			SalesRecordSharingService.publicGroupIdMapping.put(aprMetadata.SalesSharingGroupMappings__r[i].GroupName__c, groups[i].Id);
		}
	}
}