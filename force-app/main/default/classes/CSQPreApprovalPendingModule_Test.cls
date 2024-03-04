/**
 * @description
 * Test class for CSQPreApprovalPendingModule
 * @author SteveL
 * @date 2024-03-4
 * @group Tests
 * @changelog
 * 2024-03-4 - SteveL - Created
 */
@IsTest
private class CSQPreApprovalPendingModule_Test {
	/**
	 * @description to test the check eligibility logic should set the pre approval status to referred with a reason
	 */
	@IsTest
	private static void testBeforeUpdateCheckPreApprovalEligibility_diffAddress() {
		Customer_Scoping_Questionnaire__c csq = new Customer_Scoping_Questionnaire__c(
				Id = fflib_IDGenerator.generate(Customer_Scoping_Questionnaire__c.SObjectType)
		);

		Customer_Scoping_Questionnaire__c csqOld = new Customer_Scoping_Questionnaire__c(
				Id = csq.Id
		);

		Pick_Up_Location__c puLoc1 = new Pick_Up_Location__c(
				Id = fflib_IDGenerator.generate(Pick_Up_Location__c.SObjectType),
				CSQ__c = csq.Id,
				Address__c = 'test add 1'
		);

		Pick_Up_Location__c puLoc2 = new Pick_Up_Location__c(
				Id = fflib_IDGenerator.generate(Pick_Up_Location__c.SObjectType),
				CSQ__c = csq.Id,
				Address__c = 'test add 2'
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
		CSQPreApprovalPendingModule module = CSQPreApprovalPendingModule.newInstance();
		module.onBeforeUpdate(new List<Customer_Scoping_Questionnaire__c>{csq}, new Map<Id,Customer_Scoping_Questionnaire__c>{csqOld.Id=>csqOld}, uow);

		System.assertEquals(CSQAutomationTriggerHandler.PRE_APPROVAL_STATUS_REFERRED, csq.PreApprovalStatus__c, 'Pre approval status should have been updated to referred');
		System.assertEquals(CSQPreApprovalPendingModule.AUTO_REFERRAL_REASONS, csq.PreApprovalReferralReasons__c, 'Auto referred reason should have been updated according to the constant variable');
		Test.stopTest();
	}
}