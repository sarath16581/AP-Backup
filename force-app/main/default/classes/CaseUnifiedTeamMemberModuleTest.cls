/**
 * @author Seth Heang
 * @group Tests
 * @tag Case, CaseTeamMember
 * @domain Core
 * @description Test class for CaseUnifiedTeamMemberModule
 * @changelog
 * 2024-09-06 - Seth Heang - Created
 */
@IsTest(IsParallel=true)
private class CaseUnifiedTeamMemberModuleTest {
	/**
	 *	Test: AfterInsert Scenario, when a new unified case is created
	 *	validate that a new caseTeamMember is created with appropriate attribute mapping
	 */
	@IsTest
	static void testCreateNewCaseTeamMemberAfterInsertedNewUnifiedCase() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = UserInfo.getUserId();
		testCase.EnquirySubType__c = 'Late Item';

		Id unifiedRoleId = ApplicationTestDataFactoryCase.caseTeamRoleUnifiedAgent;
		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CaseTeamMembersSelector mockCaseTeamMembersSelector = (CaseTeamMembersSelector) MockUtility.mockSelector(CaseTeamMembersSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCaseTeamMembersSelector.selectByCaseIdAndMemberIdAndTeamRoleId(
				(Set<Id>) fflib_Match.eq(new Set<Id>{ testCase.Id }),
				(Set<Id>) fflib_Match.eq(new Set<Id>{ testCase.OwnerId}),
				(Set<Id>) fflib_Match.eq(new Set<Id>{ unifiedRoleId})
			)).thenReturn(new List<CaseTeamMember>());
		MockUtility.Mocks.when(mockUow.registerNew(
				(List<SObject>) fflib_Match.anyObject(),
				fflib_Match.eqBoolean(false),
				fflib_Match.anyString()
		)).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		CaseUnifiedTeamMemberModule module = CaseUnifiedTeamMemberModule.newInstance();
		module.onAfterInsert(new List<Case>{ testCase }, mockUow);
		Test.stopTest();

		fflib_ArgumentCaptor caseTeamMembersCaptor = fflib_ArgumentCaptor.forClass(List<CaseTeamMember>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerNew(
				(List<CaseTeamMember>) caseTeamMembersCaptor.capture(),
				fflib_Match.eqBoolean(false),
				fflib_Match.anyString()
		);
		List<CaseTeamMember> caseTeamMemberResult = (List<CaseTeamMember>) caseTeamMembersCaptor.getValue();
		Assert.isNotNull(caseTeamMemberResult, 'CaseTeamMember should not be null');
		Assert.areEqual(testCase.OwnerId, caseTeamMemberResult[0].MemberId, 'MemberId should match but instead got ' + caseTeamMemberResult[0].MemberId);
		Assert.areEqual(unifiedRoleId, caseTeamMemberResult[0].TeamRoleId, 'TeamRoleId should match but instead got ' + caseTeamMemberResult[0].TeamRoleId);
		Assert.areEqual(testCase.Id, caseTeamMemberResult[0].ParentId, 'ParentId should match but instead got ' + caseTeamMemberResult[0].ParentId);
	}

	/**
	*	Test: AfterUpdate Scenario, when an existing unified case is updated on the OwnerId field and there is no existing CaseTeamMember
	*	validate that a new caseTeamMember is created with appropriate attribute mapping
	*/
	@IsTest
	static void testCreateNewCaseTeamMemberAfterUpdatedExistingUnifiedCase() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = null;
		testCase.EnquirySubType__c = 'Late Item';

		Case updatedCase = testCase.clone(true,true);
		updatedCase.OwnerId = UserInfo.getUserId();
		Id unifiedRoleId = ApplicationTestDataFactoryCase.caseTeamRoleUnifiedAgent;
		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CaseTeamMembersSelector mockCaseTeamMembersSelector = (CaseTeamMembersSelector) MockUtility.mockSelector(CaseTeamMembersSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCaseTeamMembersSelector.selectByCaseIdAndMemberIdAndTeamRoleId(
				(Set<Id>) fflib_Match.eq(new Set<Id>{ updatedCase.Id }),
				(Set<Id>) fflib_Match.eq(new Set<Id>{ updatedCase.OwnerId}),
				(Set<Id>) fflib_Match.eq(new Set<Id>{ unifiedRoleId})
		)).thenReturn(new List<CaseTeamMember>());
		MockUtility.Mocks.when(mockUow.registerNew(
				(List<SObject>) fflib_Match.anyObject(),
				fflib_Match.eqBoolean(false),
				fflib_Match.anyString()
		)).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		CaseUnifiedTeamMemberModule module = CaseUnifiedTeamMemberModule.newInstance();
		module.onAfterUpdate(
				new List<Case>{ updatedCase },
				new Map<Id, Case> { testCase.Id => testCase },
				mockUow
		);
		Test.stopTest();

		fflib_ArgumentCaptor caseTeamMembersCaptor = fflib_ArgumentCaptor.forClass(List<CaseTeamMember>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerNew(
				(List<CaseTeamMember>) caseTeamMembersCaptor.capture(),
				fflib_Match.eqBoolean(false),
				fflib_Match.anyString()
		);
		List<CaseTeamMember> caseTeamMemberResult = (List<CaseTeamMember>) caseTeamMembersCaptor.getValue();
		Assert.isNotNull(caseTeamMemberResult, 'CaseTeamMember should not be null');
		Assert.areEqual(updatedCase.OwnerId, caseTeamMemberResult[0].MemberId, 'MemberId should match but instead got ' + caseTeamMemberResult[0].MemberId);
		Assert.areEqual(unifiedRoleId, caseTeamMemberResult[0].TeamRoleId, 'TeamRoleId should match but instead got ' + caseTeamMemberResult[0].TeamRoleId);
		Assert.areEqual(testCase.Id, caseTeamMemberResult[0].ParentId, 'ParentId should match but instead got ' + caseTeamMemberResult[0].ParentId);
	}

	/**
	*	Test: AfterUpdate Scenario, when an existing unified case is updated on the OwnerId field and there is existing CaseTeamMember
	*	validate that a new caseTeamMember is created with appropriate attribute mapping
	*/
	@IsTest
	static void testDoNotCreateNewCaseTeamMemberIfExistingMemberExists() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = null;
		testCase.EnquirySubType__c = 'Late Item';

		Case updatedCase = testCase.clone(true,true);
		updatedCase.OwnerId = UserInfo.getUserId();

		Id unifiedRoleId = ApplicationTestDataFactoryCase.caseTeamRoleUnifiedAgent;

		// cannot generate fake Id as sobjectType.getDescribe().getKeyPrefix() returns null, thus hardcoded the Id with setUnwritableFields()
		CaseTeamMember caseTeamMemberTest = ApplicationTestDataFactoryCase.getCaseTeamMembers(1, testCase.Id, updatedCase.OwnerId, unifiedRoleId, false)[0];
		caseTeamMemberTest = (CaseTeamMember) ApplicationTestDataFactory.setUnwritableFields(caseTeamMemberTest, new Map<String, Object>{ 'Id' => '0B6Bm000000EltWKAS' });

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CaseTeamMembersSelector mockCaseTeamMembersSelector = (CaseTeamMembersSelector) MockUtility.mockSelector(CaseTeamMembersSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCaseTeamMembersSelector.selectByCaseIdAndMemberIdAndTeamRoleId(
				(Set<Id>) fflib_Match.eq(new Set<Id>{ updatedCase.Id }),
				(Set<Id>) fflib_Match.eq(new Set<Id>{ updatedCase.OwnerId }),
				(Set<Id>) fflib_Match.eq(new Set<Id>{ unifiedRoleId })
		)).thenReturn(new List<CaseTeamMember>{caseTeamMemberTest});
		MockUtility.Mocks.when(mockUow.registerNew(
				(List<SObject>) fflib_Match.anyObject(),
				fflib_Match.eqBoolean(false),
				fflib_Match.anyString()
		)).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		CaseUnifiedTeamMemberModule module = CaseUnifiedTeamMemberModule.newInstance();
		module.onAfterUpdate(
				new List<Case>{ updatedCase },
				new Map<Id, Case> { testCase.Id => testCase },
				mockUow
		);
		Test.stopTest();

		fflib_ArgumentCaptor caseTeamMembersCaptor = fflib_ArgumentCaptor.forClass(List<CaseTeamMember>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(0))).registerNew(
				(List<CaseTeamMember>) caseTeamMembersCaptor.capture(),
				fflib_Match.eqBoolean(false),
				fflib_Match.anyString()
		);
	}
}