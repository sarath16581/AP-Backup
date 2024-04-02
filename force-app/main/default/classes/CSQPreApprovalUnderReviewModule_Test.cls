/**
 * @description
 * Test class for CSQPreApprovalUnderReviewModule
 * @author SteveL
 * @date 2024-03-14
 * @group Tests
 * @changelog
 * 2024-03-14 - SteveL - Created
 */

@IsTest
private class CSQPreApprovalUnderReviewModule_Test {
	/**
	 * @description test a csq record with pre approval status = Pending Onboarding Review, and verify the Pre-Approver field result
	 */
	@IsTest
	private static void testBeforeUpdateSetUnderReviewPreApprover() {
		Customer_Scoping_Questionnaire__c csq = new Customer_Scoping_Questionnaire__c(
				Id = fflib_IDGenerator.generate(Customer_Scoping_Questionnaire__c.SObjectType), PreApprovalStatus__c = CSQAutomationTriggerHandler.PRE_APPROVAL_STATUS_UNDER_ONBOARDING_REVIEW
		);

		Customer_Scoping_Questionnaire__c csqOld = new Customer_Scoping_Questionnaire__c(
				Id = csq.Id
		);

		// =====================================
		// Testing
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CSQAutomationTriggerHandler.getUnitOfWorkSObjectTypes());

		Test.startTest();
		CSQPreApprovalUnderReviewModule module = CSQPreApprovalUnderReviewModule.newInstance();
		module.onBeforeUpdate(new List<Customer_Scoping_Questionnaire__c>{csq}, new Map<Id,Customer_Scoping_Questionnaire__c>{csqOld.Id=>csqOld}, uow);

		System.assertEquals(UserInfo.getUserId(), csq.PreApprover__c, 'Incorrect Pre Approver has been set.');
		Test.stopTest();
	}
}