/**
 * @description
 * Test class for CSQPreApprovalAutomationModule
 * @author SteveL
 * @date 2024-03-4
 * @group Tests
 * @changelog
 * 2024-03-4 - SteveL - Created
 */

@IsTest
private class CSQPreApprovalAutomationModule_Test {
	/**
	 * @description to test enforceReferralReasons will throw error as expected
	 */
	@IsTest
	private static void testOnBeforeUpdateEnforceReferralReasons() {
		Customer_Scoping_Questionnaire__c csq = new Customer_Scoping_Questionnaire__c(
				Id = fflib_IDGenerator.generate(Customer_Scoping_Questionnaire__c.SObjectType)
		);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CSQAutomationTriggerHandler.getUnitOfWorkSObjectTypes());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CSQPreApprovalAutomationModule module = CSQPreApprovalAutomationModule.newInstance();
		module.onBeforeUpdate(new List<Customer_Scoping_Questionnaire__c>{csq}, new Map<Id,Customer_Scoping_Questionnaire__c>(), uow);

		Assert.isTrue(csq.hasErrors(), 'Expect error when PreApprovalReferralReasons__c is empty');

		Test.stopTest();
	}

	/**
	 * @description to test enterCSQApprovalUponPreApprovalNotApplicable will enter a approval process as expected
	 */
	@IsTest
	private static void testOnAfterUpdateEnterCSQApprovalUponPreApprovalNotApplicable() {
		Customer_Scoping_Questionnaire__c csqOld = new Customer_Scoping_Questionnaire__c(
				Id = fflib_IDGenerator.generate(Customer_Scoping_Questionnaire__c.SObjectType)
		);

		Customer_Scoping_Questionnaire__c csq = new Customer_Scoping_Questionnaire__c(
				Id = csqOld.Id,
				PreApprovalStatus__c = CSQAutomationTriggerHandler.PRE_APPROVAL_STATUS_REFERRED,
				PreApprovalReferralReasons__c = 'DGs'
		);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CSQAutomationTriggerHandler.getUnitOfWorkSObjectTypes());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CSQPreApprovalAutomationModule module = CSQPreApprovalAutomationModule.newInstance();
		module.onAfterUpdate(new List<Customer_Scoping_Questionnaire__c>{csq}, new Map<Id,Customer_Scoping_Questionnaire__c>{csqOld.Id=>csqOld}, uow);
		Test.stopTest();
	}
}