/**
* @description Test class covering CaseAutomationClassificationModule
* @changelog
* 2024-08-20	George Nguyen	Created and added classifyUnifiedCases(...)
* 2024-09-02	George Nguyen	Added test to check on insert the correct record type matches the Type field. Included check of values for when Type changes from Geneal Enquiry to Investigation
* 2024-09-03	George Nguyen	Included default values on Insert for type and subtype
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
}