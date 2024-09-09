/**
* @description Test class covering CaseAutomationClassificationModule
* @changelog
* 2024-08-20	George Nguyen	Created and added classifyUnifiedCases(...)
* 2024-09-02	George Nguyen	Added test to check on insert the correct record type matches the Type field. Included check of values for when Type changes from Geneal Enquiry to Investigation
* 2024-09-03	George Nguyen	Included default values on Insert for type and subtype
* 2024-09-09 - Ranjeewa Silva - Added test to verify email notifications to customer on converting general enquiry unified case to investigation type.
*/
@IsTest
class CaseAutomationClassificationModule_Test {

	/*
		Making sure that if case is of Unified Record type and Type changes from General Enquiry to Investigation, then also change the Record Type to UnifiedInvestigation
	*/
	@IsTest
	static void classifyUnifiedCases() {
		Id unifiedGeneralEnquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(SSSWConstants.UNIFIED_GENERAL_ENQUIRY_DEVELOPER_NAME).getRecordTypeId();
		Id unifiedInvestigationRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME).getRecordTypeId();

		RecordTypesSelector mockRecordTypesSelector = (RecordTypesSelector)MockUtility.mockSelector(RecordTypesSelector.class);
		ApplicationUnitOfWork mockApplicationUnitOfWork = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockRecordTypesSelector.selectByDeveloperNameLike(
																(String)fflib_Match.eq(String.valueOf(Case.getsObjectType())), 
																(String)fflib_Match.eq(SSSWConstants.UNIFIED_APP)
															)).thenReturn(new Map<Id, RecordType>{
																unifiedGeneralEnquiryRecordTypeId => new RecordType(Id = unifiedGeneralEnquiryRecordTypeId, DeveloperName = SSSWConstants.UNIFIED_GENERAL_ENQUIRY_DEVELOPER_NAME),
																unifiedInvestigationRecordTypeId => new RecordType(Id = unifiedInvestigationRecordTypeId, DeveloperName = SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME)
															});

		MockUtility.Mocks.stopStubbing();

		List<Case> caseInsertList = new List<Case>();
		Case case1 = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		case1.RecordTypeId = unifiedGeneralEnquiryRecordTypeId;
		case1.Type = SSSWConstants.INVESTIGATION; // setting the wrong type for this record type
		caseInsertList.add(case1);

		Map<Id, Case> oldMap = new Map<Id, Case>();
		List<Case> caseUpdateList = new List<Case>();
		Case case2 = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		case2.RecordTypeId = unifiedGeneralEnquiryRecordTypeId;
		case2.Type = SSSWConstants.INVESTIGATION;
		caseUpdateList.add(case2);

		Case oldCase2 = case2.clone(true, true, true, true);
		oldCase2.Type = SSSWConstants.GENERAL_ENQUIRY;
		oldMap.put(oldCase2.Id, oldCase2);

		Test.startTest();
		CaseAutomationClassificationModule module = new CaseAutomationClassificationModule();
		module.onBeforeInsert(caseInsertList, mockApplicationUnitOfWork);
		module.onBeforeUpdate(caseUpdateList, oldMap, mockApplicationUnitOfWork);
		Test.stopTest();

		System.assertEquals(unifiedInvestigationRecordTypeId, case1.RecordTypeId, 'It should be set to UnifiedInvestigation record type');
		System.assertEquals(SSSWConstants.CASE_TYPE_AND_PRODUCT_UNIFIED_MODEL, case1.Type_and_Product__c, 'Status should be set to Unified Model');
		System.assertEquals(SSSWConstants.CASE_ENQUIRY_SUBTYPE_LATE_ITEM, case1.EnquirySubType__c, 'Status should be set to Late Item');

		System.assertEquals(unifiedInvestigationRecordTypeId, case2.RecordTypeId, 'It should be set to UnifiedInvestigation record type');
		System.assertEquals(SSSWConstants.CASE_STATUS_NEW, case2.Status, 'Status should be set to New');
		System.assertEquals(SSSWConstants.CASE_TYPE_AND_PRODUCT_UNIFIED_MODEL, case2.Type_and_Product__c, 'Status should be set to Unified Model');
		System.assertEquals(SSSWConstants.CASE_ENQUIRY_SUBTYPE_LATE_ITEM, case2.EnquirySubType__c, 'Status should be set to Late Item');
	}

	/**
	 * Test to ensure email notifications are sent to the customer when unified general enquiry cases are converted into
	 * unified investigation case.
	 */
	@IsTest
	static void testCustomerEmailOnConvertingUnifiedGeneralEnquiryToUnifiedInvestigation() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(3, true);
		for (Case caseRecord: cases) {
			caseRecord.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedGeneralEnquiryRecordType;
			caseRecord.Type = SSSWConstants.CASE_TYPE_INVESTIGATION;
			caseRecord.ProductSubCategory__c = 'AusPost Test Product';
		}
		cases[2].ProductSubCategory__c = 'StarTrack Test Product';

		// cases[0] does not have customer email populated. cases[1] and cases[2] both have customer email set on related contact.
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{
				'ContactEmail' => 'test@test.invalid'
		});
		cases[2] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[2], new Map<String, Object>{
				'ContactEmail' => 'test@test.invalid'
		});

		List<Case> casesOld = new List<Case>{cases[0].clone(true), cases[1].clone(true), cases[2].clone(true)};
		// set type of oldCases to 'General Enquiry'
		casesOld[0].Type = SSSWConstants.CASE_TYPE_GENERAL_ENQUIRY;
		casesOld[1].Type = SSSWConstants.CASE_TYPE_GENERAL_ENQUIRY;
		casesOld[2].Type = SSSWConstants.CASE_TYPE_GENERAL_ENQUIRY;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseAutomationClassificationModule module = new CaseAutomationClassificationModule();
		module.onBeforeUpdate(cases, new Map<Id,Case>(casesOld), mockUow);

		Test.stopTest();

		// verify notification emails are queued for cases[1] and case[2] only. cases[0] does not have a valid contact email address
		// and an email should not be queued.
		fflib_ArgumentCaptor caseIdsArgCaptor = fflib_ArgumentCaptor.forClass(Id.class);
		fflib_ArgumentCaptor emailAlertArgCaptor = fflib_ArgumentCaptor.forClass(String.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(2))).queueEmailNotification((Id)caseIdsArgCaptor.capture(), fflib_Match.eqSObjectType(Case.SObjectType), (String)emailAlertArgCaptor.capture());

		List<Object> caseIds = (List<Object>)caseIdsArgCaptor.getAllValues();
		Assert.areEqual(2, caseIds.size(), 'Emails are expected only for two case records.');
		Assert.isTrue(caseIds.contains(cases[1].Id), 'Expected email notification not sent for cases[1] with a valid contact email');
		Assert.isTrue(caseIds.contains(cases[2].Id), 'Expected email notification not sent for cases[2] with a valid contact email');

		List<Object> emailAlertNames = (List<Object>)emailAlertArgCaptor.getAllValues();
		Assert.areEqual(2, emailAlertNames.size(), 'Emails are expected only for two case records.');
		Assert.areEqual(CaseAutomationClassificationModule.EMAIL_ALERT_UNIFIED_GENERAL_ENQUIRY_TO_INVESTIGATION_AP, emailAlertNames[0], 'Incorrect email alert used to notify customer on AP Case cases[1].');
		Assert.areEqual(CaseAutomationClassificationModule.EMAIL_ALERT_UNIFIED_GENERAL_ENQUIRY_TO_INVESTIGATION_ST, emailAlertNames[1], 'Incorrect email alert used to notify customer on ST Case cases[2].');
	}
}