/*** 
 * @author Noel Lim
 * @date 2022-10-17
 * @group Utility
 * @domain Routing 
 * @description Test class for the MyCustomerClosedCaseModule_Test class
 * @changelog
 * 2022-10-17 - Noel Lim - Created
 */
@IsTest
private class MyCustomerClosedCaseModule_Test {
	/**
	 * Covers the following positive test scenarios:
	 * a) Closed Case in a Queue with Routing config and related Agent Work
     * b) Closed Case in a Queue with Routing config, no related Agent Work
	 */
	@IsTest
	private static void testClosedCaseReassigned() {
		// =====================================
		// Data Preparation
		// =====================================		
        
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].IsNewForRouting__c  = true;
		cases[0].AllocateToQueue__c = true;
        cases[1].ReferenceID__c = 'ART1232'; // links to articles[1]
		cases[1].Origin = 'Email';
		cases[0].RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
		cases[1].IsNewForRouting__c  = true;
		cases[1].AllocateToQueue__c = true;

        //1 queue with routing config
        //old cases
        //1 user
        //1 agent work
		
		// =====================================
		// Stubbing
		// =====================================
		
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);
        
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		//MockUtility.Mocks.when(mockGroupsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(Groups));
		
        MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
        Test.stopTest();
        
	}
	
    /**
	 * Covers the following test scenarios (negative testing):
	 * a) Closed Case in a Queue without Routing config
     * b) Case not in a Closed Status
     * c) Case with no change in Status
	 * 
	 */
    @IsTest
	private static void testEnsureCaseInOmniDefaultQueue() {
		// =====================================
		// Data Preparation
		// =====================================	
        
		List<Case> cases = ApplicationTestDataFactory.getCases(3, true);
		cases[0].IsNewForRouting__c  = true;
		cases[0].AllocateToQueue__c = true;
        cases[1].ReferenceID__c = 'ART1232'; // links to articles[1]
		cases[1].Origin = 'Email';
		cases[0].RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
		cases[1].IsNewForRouting__c  = true;
		cases[1].AllocateToQueue__c = true;

        //2 queues, 1 with routing config
        //old cases - 1 is closed status and does not change
		
		// =====================================
		// Stubbing
		// =====================================
		
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);
        
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		//MockUtility.Mocks.when(mockGroupsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(Groups));
		
        MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
        Test.stopTest();
    
    }
	
}