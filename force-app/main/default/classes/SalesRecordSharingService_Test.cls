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
		System.assertEquals(APR__Share.SObjectType, mapping.shareObjectType, 'Share object type must be populated');
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
	 * Test to ensure new share records are created as expected when calling service class with recalculate=true
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

	/**
	 * Test to ensure no shares are created when Sales Record Sharing feature is disabled
	 */
	@IsTest
	static void testShareNewRecordsWhenSalesRecordSharingFeatureDisabled() {
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

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationFeatures mockApplicationFeatures = (ApplicationFeatures) MockUtility.mockUtility(ApplicationFeatures.class);

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockApplicationFeatures.isFeatureActive((String)fflib_Match.anyObject())).thenReturn(false);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesRecordSharingService.getInstance().shareRecords(APR__C.getSObjectType(), new Map<Id, APR__c>(aprs), false, mockUow);

		Test.stopTest();

		// verify no new share records registered with unit of work
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerNew((List<SObject>)fflib_Match.anyObject(), (Boolean)fflib_Match.eqBoolean(false), (String)fflib_Match.anyObject());

		// verify Application Features are checked
		fflib_ArgumentCaptor featureNameCapture = fflib_ArgumentCaptor.forClass(String.class);

		((ApplicationFeatures)MockUtility.Mocks.verify(mockApplicationFeatures, 1)).isFeatureActive((String)featureNameCapture.capture());
		String featureNameCaptured = (String) featureNameCapture.getValue();
		System.assertEquals(SalesRecordSharingService.SALES_RECORD_SHARING_FEATURE_NAME, featureNameCaptured, 'Expected to check status of feature - ' + SalesRecordSharingService.SALES_RECORD_SHARING_FEATURE_NAME + '; but not checked.' );
	}

	/**
	 * Test to verify child record sharing recalculation behaviour for accounts with high volume of child records
	 */
	@IsTest
	static void testRecalculateChildRecordSharingOnHighVolumeAccounts() {
		// =====================================
		// Data Preparation
		// =====================================

		// inject public group ids in service class so that the test doesn't depend on public group data in the org
		injectMockPublicGroupIdsInService();

		// set this limit from the test so we could test high volume scenarios
		SalesRecordSharingService.MAX_ACC_MOVEMENT_RELATED_RECORD_SIZE_PER_TRANSACTION = 12;

		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(3, true);
		for (Account parentAccount: parentAccounts) {
			parentAccount.SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_HOLDING;
		}

		List<APR__c> aprs_parentAccountOne = ApplicationTestDataFactory.getAPRs(5, null, null, true);
		for (APR__c apr: aprs_parentAccountOne) {
			apr.Legal_Entity_Name_LookUp__c = parentAccounts[0].Id;
			apr = (APR__c) ApplicationTestDataFactory.setUnwritableFields(apr, new Map<String, Object>{'Legal_Entity_Name_LookUp__r' => parentAccounts[0]});
		}
		parentAccounts[0] = (Account) ApplicationTestDataFactory.setChildRelationships(parentAccounts[0], new Map<String, List<SObject>>{'APRs__r' => aprs_parentAccountOne});

		List<APR__c> aprs_parentAccountTwo = ApplicationTestDataFactory.getAPRs(10, null, null, true);
		for (APR__c apr: aprs_parentAccountTwo) {
			apr.Legal_Entity_Name_LookUp__c = parentAccounts[1].Id;
			apr = (APR__c) ApplicationTestDataFactory.setUnwritableFields(apr, new Map<String, Object>{'Legal_Entity_Name_LookUp__r' => parentAccounts[1]});
		}
		parentAccounts[1] = (Account) ApplicationTestDataFactory.setChildRelationships(parentAccounts[1], new Map<String, List<SObject>>{'APRs__r' => aprs_parentAccountTwo});

		List<APR__c> aprs_parentAccountThree = ApplicationTestDataFactory.getAPRs(15, null, null, true);
		for (APR__c apr: aprs_parentAccountThree) {
			apr.Legal_Entity_Name_LookUp__c = parentAccounts[2].Id;
			apr = (APR__c) ApplicationTestDataFactory.setUnwritableFields(apr, new Map<String, Object>{'Legal_Entity_Name_LookUp__r' => parentAccounts[2]});
		}
		parentAccounts[2] = (Account) ApplicationTestDataFactory.setChildRelationships(parentAccounts[2], new Map<String, List<SObject>>{'APRs__r' => aprs_parentAccountThree});


		// =====================================
		// Stubbing
		// =====================================
		BusinessAccountsSelector mockBusinessAccountsSelector = ((BusinessAccountsSelector) MockUtility.mockSelector(BusinessAccountsSelector.class));
		SObjectSharesSelector mockSObjectSharesSelector = ((SObjectSharesSelector) MockUtility.mockSelector(SObjectSharesSelector.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockBusinessAccountsSelector.selectByIdWithChildRecords((Set<Id>)fflib_Match.anyObject(), (Map<SObjectType, String>)fflib_Match.anyObject())).thenReturn(parentAccounts);
		MockUtility.Mocks.when(mockSObjectSharesSelector.setShareSobjectType((SObjectType)fflib_Match.anyObject())).thenReturn(mockSObjectSharesSelector);
		MockUtility.Mocks.when(mockSObjectSharesSelector.selectByParentIdAndRowCause((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(new List<SObject>());
		MockUtility.Mocks.when(mockUow.registerNew((SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult> results = SalesRecordSharingService.getInstance().recalculateChildRecordSharing(new Map<Id, Account>(parentAccounts).keySet(), mockUow);

		Test.stopTest();

		// verify the results returned from service
		System.assertEquals(3, results.size(), 'Expected results of each of the accounts passed in');
		for (SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult result: results) {
			if (result.accountId == parentAccounts[0].Id) {
				System.assertEquals(true, result.processed, 'Expected results to indicate the account is successfully processed.');
				System.assertEquals(false, result.retryInPartialMode, 'Expected results to indicate partial processing is not required for processed account.');
			} else if  (result.accountId == parentAccounts[1].Id) {
				System.assertEquals(false, result.processed, 'Expected results to indicate the account is not processed.');
				System.assertEquals(false, result.retryInPartialMode, 'Expected results to indicate partial processing is not required for account.');
			} else {
				System.assertEquals(false, result.processed, 'Expected results to indicate the account is not processed.');
				System.assertEquals(true, result.retryInPartialMode, 'Expected results to indicate partial processing is required for account.');
				System.assertEquals(1, result.unprocessedChildSObjectTypes.size(), 'Results should have unprocessed child SObjectTypes specified');
			}
		}
	}

	/**
	 * Test to ensure sharing is recalculated as expected on child records of accounts
	 */
	@IsTest
	static void testRecalculateChildRecordSharing() {
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

		List<Apttus__APTS_Agreement__c> apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, null, null, true);
		apttusContracts[0].Apttus__Account__c = parentAccounts[0].Id;

		apttusContracts[0] = (Apttus__APTS_Agreement__c) ApplicationTestDataFactory.setUnwritableFields(apttusContracts[0], new Map<String, Object>{'Apttus__Account__r' => parentAccounts[0]});

		parentAccounts[0] = (Account) ApplicationTestDataFactory.setChildRelationships(parentAccounts[0], new Map<String, List<SObject>>{'APRs__r' => aprs, 'Apttus__R00N50000001Xl0UEAS__r' => apttusContracts});

		//List<Group> publicGroups = ApplicationTestDataFactory.getGroups(3, SalesRecordSharingService.PUBLIC_GROUP_TYPES_SUPPORTED.iterator().next(), true);
		//SalesSharingObjectMapping__mdt metadata = SalesRecordSharingService.salesSharingMetadata.get(String.valueOf(APR__c.SObjectType));

		//List<APR__Share> existingAPRShares = new List<APR__Share>();
		//existingAPRShares.add(new APR__Share(ParentId=aprs[0].Id, UserOrGroupId=publicGroups[0].Id, AccessLevel='View', RowCause=metadata.SharingReasonName__c));

		// =====================================
		// Stubbing
		// =====================================
		BusinessAccountsSelector mockBusinessAccountsSelector = ((BusinessAccountsSelector) MockUtility.mockSelector(BusinessAccountsSelector.class));
		SObjectSharesSelector mockSObjectSharesSelector = ((SObjectSharesSelector) MockUtility.mockSelector(SObjectSharesSelector.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockBusinessAccountsSelector.selectByIdWithChildRecords((Set<Id>)fflib_Match.anyObject(), (Map<SObjectType, String>)fflib_Match.anyObject())).thenReturn(parentAccounts);
		MockUtility.Mocks.when(mockSObjectSharesSelector.setShareSobjectType((SObjectType)fflib_Match.anyObject())).thenReturn(mockSObjectSharesSelector);
		//TODO Investigate how to mock SObjectSharesSelector properly with the chained setShareSobjectType method. We need
		// separate selector instances when querying '__Share' sobjects of different types.
		//MockUtility.Mocks.when(mockSObjectSharesSelector.selectByParentIdAndRowCause((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(existingAPRShares);
		MockUtility.Mocks.when(mockSObjectSharesSelector.selectByParentIdAndRowCause((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(new List<SObject>());
		MockUtility.Mocks.when(mockUow.registerNew((SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		((ApplicationUnitOfWork)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockUow)).registerDeleted((SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult> results = SalesRecordSharingService.getInstance().recalculateChildRecordSharing(new Map<Id, Account>(parentAccounts).keySet(), mockUow);

		Test.stopTest();

		// verify the results returned from service
		System.assertEquals(1, results.size(), 'Expected results of each of the accounts passed in');
		System.assertEquals(parentAccounts[0].Id, results[0].accountId, 'Expected account id to be populated in returned results.');
		System.assertEquals(true, results[0].processed, 'Expected results to indicate the account is successfully processed.');
		System.assertEquals(false, results[0].retryInPartialMode, 'Expected results to indicate partial processing is not required for processed account.');
		System.assertEquals(0, results[0].unprocessedChildSObjectTypes.size(), 'Results should not have unprocessed child SObjectTypes specified for a processed account');

		// verify new share records registered with unit of work are as expected
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(SObject.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 2)).registerNew((SObject)sobjectCapture.capture(), (Boolean)fflib_Match.eqBoolean(false), (String)fflib_Match.anyObject());
		List<Object> newShares = (List<Object>) sobjectCapture.getAllValues();

		for (Object newShare: newShares) {
			if (newShare instanceof APR__Share) {
				System.assertEquals(aprs[0].Id, ((APR__Share)newShare).ParentId, 'Unexpected share record created');
				SalesSharingObjectMapping__mdt metadata = SalesRecordSharingService.salesSharingMetadata.get(String.valueOf(APR__c.SObjectType));
				System.assertEquals(metadata.SharingReasonName__c, ((APR__Share)newShare).RowCause, 'Incorrect sharing reason specified on share record');
			} else if (newShare instanceof Apttus__APTS_Agreement__Share) {
				System.assertEquals(apttusContracts[0].Id, ((Apttus__APTS_Agreement__Share)newShare).ParentId, 'Unexpected share record created');
				SalesSharingObjectMapping__mdt metadata = SalesRecordSharingService.salesSharingMetadata.get(String.valueOf(Apttus__APTS_Agreement__c.SObjectType));
				System.assertEquals(metadata.SharingReasonName__c, ((Apttus__APTS_Agreement__Share)newShare).RowCause, 'Incorrect sharing reason specified on share record');
			} else {
				System.assert(false, 'Unexpected share record SObjectType');
			}
		}

		// verify no shares deleted
		fflib_ArgumentCaptor deletedSObjectsCapture = fflib_ArgumentCaptor.forClass(SObject.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerDeleted((SObject)deletedSObjectsCapture.capture(), (Boolean)fflib_Match.eqBoolean(false), (String)fflib_Match.anyObject());
	}

	/**
	 * Test to ensure sharing is recalculated as expected on child records when calling overloaded service method that also manage
	 * the unit of work on behalf of callers.
	 */
	@IsTest
	static void testRecalculateChildRecordSharingWhenNoUnitOfWorkInstanceAvailable() {
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

		List<Apttus__APTS_Agreement__c> apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, null, null, true);
		apttusContracts[0].Apttus__Account__c = parentAccounts[0].Id;

		apttusContracts[0] = (Apttus__APTS_Agreement__c) ApplicationTestDataFactory.setUnwritableFields(apttusContracts[0], new Map<String, Object>{'Apttus__Account__r' => parentAccounts[0]});

		parentAccounts[0] = (Account) ApplicationTestDataFactory.setChildRelationships(parentAccounts[0], new Map<String, List<SObject>>{'APRs__r' => aprs, 'Apttus__R00N50000001Xl0UEAS__r' => apttusContracts});

		// =====================================
		// Stubbing
		// =====================================
		BusinessAccountsSelector mockBusinessAccountsSelector = ((BusinessAccountsSelector) MockUtility.mockSelector(BusinessAccountsSelector.class));
		SObjectSharesSelector mockSObjectSharesSelector = ((SObjectSharesSelector) MockUtility.mockSelector(SObjectSharesSelector.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockBusinessAccountsSelector.selectByIdWithChildRecords((Set<Id>)fflib_Match.anyObject(), (Map<SObjectType, String>)fflib_Match.anyObject())).thenReturn(parentAccounts);
		MockUtility.Mocks.when(mockSObjectSharesSelector.setShareSobjectType((SObjectType)fflib_Match.anyObject())).thenReturn(mockSObjectSharesSelector);
		MockUtility.Mocks.when(mockSObjectSharesSelector.selectByParentIdAndRowCause((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(new List<SObject>());
		MockUtility.Mocks.when(mockUow.registerNew((SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		((ApplicationUnitOfWork)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockUow)).registerDeleted((SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult> results = SalesRecordSharingService.getInstance().recalculateChildRecordSharing(new Map<Id, Account>(parentAccounts).keySet());

		Test.stopTest();

		// verify the results returned from service
		System.assertEquals(1, results.size(), 'Expected results of each of the accounts passed in');
		System.assertEquals(parentAccounts[0].Id, results[0].accountId, 'Expected account id to be populated in returned results.');
		System.assertEquals(true, results[0].processed, 'Expected results to indicate the account is successfully processed.');
		System.assertEquals(false, results[0].retryInPartialMode, 'Expected results to indicate partial processing is not required for processed account.');
		System.assertEquals(0, results[0].unprocessedChildSObjectTypes.size(), 'Results should not have unprocessed child SObjectTypes specified for a processed account');

		// verify sobject types configured in metadata are registered with unit of work
		fflib_ArgumentCaptor sObjectTypesCapture = fflib_ArgumentCaptor.forClass(List<Schema.SObjectType>.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerSObjectTypes((List<Schema.SObjectType>)sObjectTypesCapture.capture());
		List<Schema.SObjectType> registeredSObjectTypes = (List<Schema.SObjectType>) sObjectTypesCapture.getValue();
		System.assertEquals(SalesRecordSharingService.salesSharingMetadata.size(), registeredSObjectTypes.size(), 'SObject Types configured in custom metadata is not configured in unit of work instance');

		// verify unit of work is committed by the service
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).commitWork();
	}

	/**
	 * Test to ensure sharing recalculation is bypassed when feature is disabled
	 */
	@IsTest
	static void testRecalculateChildRecordSharingIsBypassedWhenFeatureIsDisabled() {
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

		// =====================================
		// Stubbing
		// =====================================
		ApplicationFeatures mockApplicationFeatures = (ApplicationFeatures) MockUtility.mockUtility(ApplicationFeatures.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockApplicationFeatures.isFeatureActive((String)fflib_Match.anyObject())).thenReturn(false);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult> results = SalesRecordSharingService.getInstance().recalculateChildRecordSharing(new Map<Id, Account>(parentAccounts).keySet(), mockUow);

		Test.stopTest();

		// verify Application Features are checked
		fflib_ArgumentCaptor featureNameCapture = fflib_ArgumentCaptor.forClass(String.class);
		((ApplicationFeatures)MockUtility.Mocks.verify(mockApplicationFeatures, 1)).isFeatureActive((String)featureNameCapture.capture());
		String featureNameCaptured = (String) featureNameCapture.getValue();
		System.assertEquals(SalesRecordSharingService.SALES_RECORD_SHARING_FEATURE_NAME, featureNameCaptured, 'Expected to check status of feature - ' + SalesRecordSharingService.SALES_RECORD_SHARING_FEATURE_NAME + '; but not checked.' );

		// verify the results returned from service
		System.assertEquals(0, results.size(), 'Expected empty result set when the feature is disabled');

		// verify no new share records registered with unit of work
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerNew((SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.eqBoolean(false), (String)fflib_Match.anyObject());

		// verify no shares deleted
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerDeleted((SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.eqBoolean(false), (String)fflib_Match.anyObject());
	}

	/**
	 * Test to ensure sharing is recalculated for specified child sobject types of accounts when recalculating sharing in
	 * partial mode
	 */
	@IsTest
	static void testRecalculateChildRecordSharingInPartialMode() {
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

		List<Apttus__APTS_Agreement__c> apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, null, null, true);
		apttusContracts[0].Apttus__Account__c = parentAccounts[0].Id;

		apttusContracts[0] = (Apttus__APTS_Agreement__c) ApplicationTestDataFactory.setUnwritableFields(apttusContracts[0], new Map<String, Object>{'Apttus__Account__r' => parentAccounts[0]});

		parentAccounts[0] = (Account) ApplicationTestDataFactory.setChildRelationships(parentAccounts[0], new Map<String, List<SObject>>{'APRs__r' => aprs, 'Apttus__R00N50000001Xl0UEAS__r' => apttusContracts});

		// =====================================
		// Stubbing
		// =====================================
		BusinessAccountsSelector mockBusinessAccountsSelector = ((BusinessAccountsSelector) MockUtility.mockSelector(BusinessAccountsSelector.class));
		SObjectSharesSelector mockSObjectSharesSelector = ((SObjectSharesSelector) MockUtility.mockSelector(SObjectSharesSelector.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockBusinessAccountsSelector.selectByIdWithChildRecords((Set<Id>)fflib_Match.anyObject(), (Map<SObjectType, String>)fflib_Match.anyObject())).thenReturn(parentAccounts);
		MockUtility.Mocks.when(mockSObjectSharesSelector.setShareSobjectType((SObjectType)fflib_Match.anyObject())).thenReturn(mockSObjectSharesSelector);
		MockUtility.Mocks.when(mockSObjectSharesSelector.selectByParentIdAndRowCause((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(new List<SObject>());
		MockUtility.Mocks.when(mockUow.registerNew((SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		((ApplicationUnitOfWork)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockUow)).registerDeleted((SObject)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject(), (String)fflib_Match.anyObject());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// recalculate sharing only for specified child sobject type
		SalesRecordSharingService.getInstance().recalculateChildRecordSharing(new Map<Id, Account>(parentAccounts).keySet(), APR__c.getSObjectType());

		Test.stopTest();

		// verify sobject type passed in is registered with unit of work
		fflib_ArgumentCaptor sObjectTypesCapture = fflib_ArgumentCaptor.forClass(List<Schema.SObjectType>.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerSObjectTypes((List<Schema.SObjectType>)sObjectTypesCapture.capture());
		List<Schema.SObjectType> registeredSObjectTypes = (List<Schema.SObjectType>) sObjectTypesCapture.getValue();
		System.assertEquals(1, registeredSObjectTypes.size(), 'Unit of Work instance should only support DML on Share records of the SObject Type specified.');
		System.assertEquals(APR__Share.getSObjectType(), registeredSObjectTypes[0], 'Unit of Work instance should only support DML on Share records of the SObject Type specified.');

		// verify new share records registered with unit of work only for APR__c
		// sharing for apttusContracts should not be attempted as we are only passing "APR__c.getSObjectType()" in to
		// service method for sharing recalculation
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(SObject.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((SObject)sobjectCapture.capture(), (Boolean)fflib_Match.eqBoolean(false), (String)fflib_Match.anyObject());
		List<Object> newShares = (List<Object>) sobjectCapture.getAllValues();

		for (Object newShare: newShares) {
			if (newShare instanceof APR__Share) {
				System.assertEquals(aprs[0].Id, ((APR__Share)newShare).ParentId, 'Unexpected share record created');
				SalesSharingObjectMapping__mdt metadata = SalesRecordSharingService.salesSharingMetadata.get(String.valueOf(APR__c.SObjectType));
				System.assertEquals(metadata.SharingReasonName__c, ((APR__Share)newShare).RowCause, 'Incorrect sharing reason specified on share record');
			} else {
				System.assert(false, 'Unexpected share record SObjectType');
			}
		}

		// verify no shares deleted
		fflib_ArgumentCaptor deletedSObjectsCapture = fflib_ArgumentCaptor.forClass(SObject.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerDeleted((SObject)deletedSObjectsCapture.capture(), (Boolean)fflib_Match.eqBoolean(false), (String)fflib_Match.anyObject());

		// verify unit of work is committed by the service
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).commitWork();
	}

	/**
	 * Test to ensure sharing is recalculated as expected on child records of accounts by the queueable job
	 */
	@IsTest
	static void testRecalculateChildRecordSharingQueueable() {
		// =====================================
		// Data Preparation
		// =====================================

		// inject public group ids in service class so that the test doesn't depend on public group data in the org
		injectMockPublicGroupIdsInService();

		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(3, true);
		for (Account parentAccount: parentAccounts) {
			parentAccount.SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;
		}

		// setup the results returned by the service
		List<SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult> recalculationResults = new List<SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult>();
		// parentAccounts[0] is processed fully
		recalculationResults.add(new SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult(parentAccounts[0].Id, parentAccounts[0].SalesTeamType__c, true, false, new Map<SObjectType, Integer>()));

		// parentAccounts[1] is not processed but does not require partial processing
		recalculationResults.add(new SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult(parentAccounts[1].Id, parentAccounts[1].SalesTeamType__c, false, false, new Map<SObjectType, Integer>{
				APR__c.getSObjectType() => 1000
		}));

		// parentAccounts[2] is not processed and require partial processing
		recalculationResults.add(new SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult(parentAccounts[2].Id, parentAccounts[2].SalesTeamType__c, false, true, new Map<SObjectType, Integer>{
				APR__c.getSObjectType() => 4000,
				Apttus__APTS_Agreement__c.getSObjectType() => 4200
		}));

		// =====================================
		// Stubbing
		// =====================================
		SalesRecordSharingService mockService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);
		ApplicationDatabase mockApplicationDatabase = (ApplicationDatabase) MockUtility.mockUtility(ApplicationDatabase.class);

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.recalculateChildRecordSharing((Set<Id>)fflib_Match.anyObject())).thenReturn(recalculationResults);
		MockUtility.Mocks.when(mockApplicationDatabase.enqueueJob((Object)fflib_Match.anyObject())).thenReturn(null);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable queueable = new SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable(new Map<Id, Account>(parentAccounts).keySet());
		System.enqueueJob(queueable);

		Test.stopTest();

		// verify account Id's passed into the service for sharing recalculation
		fflib_ArgumentCaptor accountIdsCaptor = fflib_ArgumentCaptor.forClass(Set<Id>.class);
		((SalesRecordSharingService)MockUtility.Mocks.verify(mockService, 1)).recalculateChildRecordSharing((Set<Id>)accountIdsCaptor.capture());
		Set<Id> accountIdsCaptured = (Set<Id>) accountIdsCaptor.getValue();
		System.assertEquals(parentAccounts.size(), accountIdsCaptured.size(), 'Expected account ids not passed into the service for recalculating sharing');
		System.assert(accountIdsCaptured.containsAll(new Map<Id, Account>(parentAccounts).keySet()), 'Expected account ids not passed into the service for recalculating sharing');

		fflib_ArgumentCaptor chainedQueueableCaptor = fflib_ArgumentCaptor.forClass(SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable.class);
		//((ApplicationDatabase)MockUtility.Mocks.verify(mockApplicationDatabase, 1)).enqueueJob(fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockApplicationDatabase, 1)).enqueueJob((SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable)chainedQueueableCaptor.capture());
		SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable chainedQueueable = (SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable) chainedQueueableCaptor.getValue();

		// verify parameters passed into the chained queueable
		System.assert(chainedQueueable.accountIds.contains(parentAccounts[1].Id), 'Expected parentAccount[1] to be passed in to the chained queueable for processing');
		System.assert(chainedQueueable.accountIdsForPartialProcessing.keySet().contains(parentAccounts[2].Id), 'Expected parentAccount[2] to be passed in to the chained queueable for partial processing');
	}

	/**
    * Test to ensure sharing is recalculated in partial mode for accounts by the queueable job
    */
	@IsTest
	static void testRecalculateChildRecordSharingInPartialModeQueueable() {
		// =====================================
		// Data Preparation
		// =====================================

		// inject public group ids in service class so that the test doesn't depend on public group data in the org
		injectMockPublicGroupIdsInService();

		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(1, true);
		for (Account parentAccount: parentAccounts) {
			parentAccount.SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;
		}

		// setup parameter to pass into queueable
		Map<Id, List<SObjectType>> accountIdsForPartialProcessing = new Map<Id, List<SObjectType>>{
				parentAccounts[0].Id => new List<SObjectType>{APR__c.getSObjectType(), Apttus__APTS_Agreement__c.getSObjectType()}
		};

		// =====================================
		// Stubbing
		// =====================================
		SalesRecordSharingService mockService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);
		ApplicationDatabase mockApplicationDatabase = (ApplicationDatabase) MockUtility.mockUtility(ApplicationDatabase.class);

		// set up responses
		MockUtility.Mocks.startStubbing();
		((SalesRecordSharingService)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockService)).recalculateChildRecordSharing((Set<Id>)fflib_Match.anyObject(), (SObjectType)fflib_Match.anyObject());
		MockUtility.Mocks.when(mockApplicationDatabase.enqueueJob((Object)fflib_Match.anyObject())).thenReturn(null);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable queueable = new SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable(new Set<Id>(), accountIdsForPartialProcessing);
		System.enqueueJob(queueable);

		Test.stopTest();

		// verify account Id's passed into the service for sharing recalculation
		fflib_ArgumentCaptor accountIdsCaptor = fflib_ArgumentCaptor.forClass(Set<Id>.class);
		fflib_ArgumentCaptor sObjectTypeCaptor = fflib_ArgumentCaptor.forClass(SObjectType.class);
		((SalesRecordSharingService)MockUtility.Mocks.verify(mockService, 1)).recalculateChildRecordSharing((Set<Id>)accountIdsCaptor.capture(), (SObjectType) sObjectTypeCaptor.capture());
		Set<Id> accountIdsCaptured = (Set<Id>) accountIdsCaptor.getValue();
		System.assertEquals(parentAccounts.size(), accountIdsCaptured.size(), 'Expected account ids not passed into the service for recalculating sharing');
		System.assert(accountIdsCaptured.containsAll(new Map<Id, Account>(parentAccounts).keySet()), 'Expected account ids not passed into the service for recalculating sharing');
		SObjectType sobjectTypeCaptured = (SObjectType) sObjectTypeCaptor.getValue();
		System.assertEquals(APR__c.getSObjectType(), sobjectTypeCaptured, 'Only one SObject Type must be passed in for sharing recalculation in partial mode');

		fflib_ArgumentCaptor chainedQueueableCaptor = fflib_ArgumentCaptor.forClass(SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockApplicationDatabase, 1)).enqueueJob((SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable)chainedQueueableCaptor.capture());
		SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable chainedQueueable = (SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable) chainedQueueableCaptor.getValue();

		// verify parameters passed into the chained queueable
		System.assert(chainedQueueable.accountIds.isEmpty(), 'No accounts must be passed in for full processing by chained queueable');
		System.assert(chainedQueueable.accountIdsForPartialProcessing.keySet().contains(parentAccounts[0].Id), 'Expected parentAccount[0] to be passed in to the chained queueable for partial processing');
		System.assertEquals(Apttus__APTS_Agreement__c.getSObjectType(), chainedQueueable.accountIdsForPartialProcessing.get(parentAccounts[0].Id)[0], 'Expected remaining sobjecttypes for parentAccount[0] to be passed in chained queueable');
	}

	/**
	 * Test to ensure a queueable job is enqueued for recalculating child record sharing for the specified account ids
	 */
	@IsTest
	static void testEnqueueChildRecordsSharingHandlerQueueable() {
		// =====================================
		// Data Preparation
		// =====================================

		// inject public group ids in service class so that the test doesn't depend on public group data in the org
		injectMockPublicGroupIdsInService();

		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(3, true);
		for (Account parentAccount: parentAccounts) {
			parentAccount.SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;
		}

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockApplicationDatabase = (ApplicationDatabase) MockUtility.mockUtility(ApplicationDatabase.class);

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockApplicationDatabase.enqueueJob((Object)fflib_Match.anyObject())).thenReturn(null);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesRecordSharingService.getInstance().enqueueChildRecordsSharingHandlerQueueable(new Map<Id,Account>(parentAccounts).keySet());

		Test.stopTest();

		// verify enqueued queueable instance has been instantiated with expected account Id's.
		fflib_ArgumentCaptor queueableInstanceCaptor = fflib_ArgumentCaptor.forClass(SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockApplicationDatabase, 1)).enqueueJob((SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable) queueableInstanceCaptor.capture());
		SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable queueableCaptured = (SalesRecordSharingService.SalesAccountChildRecordsSharingHandlerQueueable) queueableInstanceCaptor.getValue();
		System.assert(queueableCaptured != null, 'Valid queueable instance is expected');
		System.assertEquals(parentAccounts.size(), queueableCaptured.accountIds.size(), 'Expected account ids not passed into the enqueued queueable instance');
		System.assert(queueableCaptured.accountIds.containsAll(new Map<Id, Account>(parentAccounts).keySet()), 'Expected account ids not passed into the enqueued queueable instance');
	}

	private static void injectMockPublicGroupIdsInService() {
		SalesSharingObjectMapping__mdt aprMetadata = SalesRecordSharingService.salesSharingMetadata.get(String.valueOf(APR__c.getSObjectType()));
		List<Group> groups = ApplicationTestDataFactory.getGroups(aprMetadata.SalesSharingGroupMappings__r.size(), SalesRecordSharingService.PUBLIC_GROUP_TYPES_SUPPORTED.iterator().next(), true);
		for (Integer i=0; i < aprMetadata.SalesSharingGroupMappings__r.size(); i++) {
			SalesRecordSharingService.publicGroupIdMapping.put(aprMetadata.SalesSharingGroupMappings__r[i].GroupName__c, groups[i].Id);
		}
	}
}