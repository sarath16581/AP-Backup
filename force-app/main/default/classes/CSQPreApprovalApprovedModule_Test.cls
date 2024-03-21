/**
 * @description
 * Test class for CSQPreApprovalApprovedModule
 * @author SteveL
 * @date 2024-03-4
 * @group Tests
 * @changelog
 * 2024-03-4 - SteveL - Created
 */

@IsTest
private class CSQPreApprovalApprovedModule_Test {
	/**
	 * @description test the setPickupLocationApproval method to have the status as expected
	 */
	@IsTest
	private static void testSetPickupLocationApproval() {
		Customer_Scoping_Questionnaire__c csq = new Customer_Scoping_Questionnaire__c(
				Id = fflib_IDGenerator.generate(Customer_Scoping_Questionnaire__c.SObjectType)
		);

		Customer_Scoping_Questionnaire__c csqOld = new Customer_Scoping_Questionnaire__c(
				Id = csq.Id,
				PreApprovalStatus__c = CSQAutomationTriggerHandler.PRE_APPROVAL_STATUS_APPROVED
		);

		Pick_Up_Location__c puLoc1 = new Pick_Up_Location__c(
				Id = fflib_IDGenerator.generate(Pick_Up_Location__c.SObjectType),
				CSQ__c = csq.Id,
				Address__c = 'test add 1'
		);

		Pick_Up_Location__c puLoc2 = new Pick_Up_Location__c(
				Id = fflib_IDGenerator.generate(Pick_Up_Location__c.SObjectType),
				CSQ__c = csq.Id,
				Address__c = 'test add 1'
		);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CSQAutomationTriggerHandler.getUnitOfWorkSObjectTypes());
		PickUpLocationSelector selector = (PickUpLocationSelector)MockUtility.mockSelector(PickUpLocationSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(selector.selectByParentId(new Set<Id>{csq.Id}, new Set<Object>())).thenReturn(new List<Pick_Up_Location__c>{puLoc1,puLoc2});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		System.assertNotEquals(CSQPreApprovalApprovedModule.APPROVED_STATUS, puLoc1.Pick_up_Location_Status__c, 'Pick up location status should be not be approved before module execution');
		System.assertNotEquals(CSQPreApprovalApprovedModule.APPROVED_STATUS, puLoc2.Pick_up_Location_Status__c, 'Pick up location status should be not be approved before module execution');

		CSQPreApprovalApprovedModule module = CSQPreApprovalApprovedModule.newInstance();
		module.onAfterUpdate(new List<Customer_Scoping_Questionnaire__c>{csq}, new Map<Id,Customer_Scoping_Questionnaire__c>{csqOld.Id=>csqOld}, uow);

		System.assertEquals(CSQPreApprovalApprovedModule.APPROVED_STATUS, puLoc1.Pick_up_Location_Status__c, 'Pick up location status should be be approved after module execution');
		System.assertEquals(CSQPreApprovalApprovedModule.APPROVED_STATUS, puLoc2.Pick_up_Location_Status__c, 'Pick up location status should be be approved after module execution');
		Test.stopTest();
	}
}