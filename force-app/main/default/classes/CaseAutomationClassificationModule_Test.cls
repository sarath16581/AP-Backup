/**
* @description Test class covering CaseAutomationClassificationModule
* @changelog
* 2024-08-20	George Nguyen	Created and added classifyUnifiedCases(...)
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

		Map<Id, Case> oldMap = new Map<Id, Case>();
		List<Case> caseList = new List<Case>();
		Case case1 = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		case1.RecordTypeId = unifiedGeneralEnquiryRecordTypeId;
		case1.Type = SSSWConstants.INVESTIGATION;
		caseList.add(case1);

		Case oldCase1 = case1.clone(true, true, true, true);
		oldCase1.Type = SSSWConstants.GENERAL_ENQUIRY;
		oldMap.put(oldCase1.Id, oldCase1);

		Test.startTest();
		CaseAutomationClassificationModule module = new CaseAutomationClassificationModule();
		module.onBeforeUpdate(caseList, oldMap, mockApplicationUnitOfWork);
		Test.stopTest();

		System.assertEquals(unifiedInvestigationRecordTypeId, case1.RecordTypeId, 'It should be set to UnifiedInvestigation record type');
		System.assertEquals(SSSWConstants.CASE_STATUS_NEW, case1.Status, 'Status should be set to New');
	}
}