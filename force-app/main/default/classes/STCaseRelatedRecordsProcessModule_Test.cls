/**
 * @description       : Test class for STCaseRelatedRecordsProcessModule
 * @author            : Dattaraj Deshmukh
 * @domain            : Case
 * @changelog
 * 2022-12-05 - Dattaraj Deshmukh - created
 **/
@IsTest
private class STCaseRelatedRecordsProcessModule_Test {

	/**
	*Testing whenever a case is closed, all its child case investigations need to be closed.  
	*/
    @IsTest
	static void onAfterUpdate() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].Status = 'Closed'; //setting updated case status

		//cloning existing case to make it old case.
		Case oldCase = cases[0].clone(true);
		oldCase.Status = 'New'; //setting status of OLD Case record. (Trigger.Old)

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();		
		STCaseInvestigationLifecycleModule mockModuleUtil = (STCaseInvestigationLifecycleModule) MockUtility.mockUtility(STCaseInvestigationLifecycleModule.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		//passing updated value, old value and unit of work for case.
		STCaseRelatedRecordsProcessingModule.newInstance().onAfterUpdate(cases, new Map<Id, Case>{oldCase.Id => oldCase}, mockUow);

		Test.stopTest();

		//verify that STCaseInvestigationLifecycleModule is called once with expected list of jobs
		((STCaseInvestigationLifecycleModule) MockUtility.Mocks.verify(mockModuleUtil, MockUtility.Mocks.times(1))).updateAllCaseInvestigations(cases, new Map<Id, Case>{oldCase.Id => oldCase}, mockUow);
		
		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}
}