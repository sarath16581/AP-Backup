/**
* @description Test class for Case Hand-off Badge for classic case view
* @author paul Perry
* @date 2024-06-18
* @changelog
* 2024-06-18 - Paul Perry - Case Hand-off
**/
@isTest
public class CaseHandOffIndicatorController_Test {
	@isTest
	static void testGetShowBannerWithTransferDate() {
		// Create a test case with a transfer date
		Case testCaseWithDate = new Case(
			Id = fflib_IDGenerator.generate(Case.SObjectType),
			Subject = 'Test Case with Transfer Date',
			Status = 'New',
			CaseTransferDate__c = Date.today(),
			RecordType = new RecordType(DeveloperName = 'SSSW')
		);

		// Create a test case without a transfer date
		Case testCaseWithoutDate = new Case(
			Id = fflib_IDGenerator.generate(Case.SObjectType),
			Subject = 'Test Case without Transfer Date',
			Status = 'New',
			CaseTransferDate__c = null,
			RecordType = new RecordType(DeveloperName = 'SSSW')
		);

		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

		// Set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
			mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())
		).thenReturn(
			new Map<Id,Case>(new List<Case>{ testCaseWithDate, testCaseWithoutDate })
		);
		MockUtility.Mocks.stopStubbing();

		// Create a StandardController and the controller under test
		CaseHandOffIndicatorController controller = new CaseHandOffIndicatorController(
			new ApexPages.StandardController(testCaseWithDate)
		);
		
		// Verify that the banner should be shown
		System.assert(controller.getShowBanner(), 'Banner visibility should return true');
		System.assertNotEquals(null, controller.getBackgroundColor(), 'Background colour should\'ve been returned');

		// Create a StandardController and the controller under test
		controller = new CaseHandOffIndicatorController(
			new ApexPages.StandardController(testCaseWithoutDate)
		);
		
		// Verify that the banner should not be shown
		System.assert(!controller.getShowBanner(), 'Banner visibility should return false');
	}
}