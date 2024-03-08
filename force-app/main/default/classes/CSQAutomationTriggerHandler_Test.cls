/***
 * @description Test class for CSQAutomationTriggerHandler
 * @author SteveL
 * @date 2024-3-04
 * @changelog
 * 2024-3-04 - SteveL - created
 */

@IsTest
private class CSQAutomationTriggerHandler_Test {
	/**
	 * This class does not do much so we just need a single test for coverage
	 */
	@IsTest
	private static void testForCoverage() {
		CSQAutomationTriggerHandler handler = new CSQAutomationTriggerHandler();

		handler.registerModules();

		System.assert(Customer_Scoping_Questionnaire__c.SObjectType == handler.getSObjectType());
		System.assert(handler.newUnitOfWork() != null, 'Expected a valid unit of work instance, but got null');

		List<Customer_Scoping_Questionnaire__c> csqs = new List<Customer_Scoping_Questionnaire__c>();
		csqs.add(new Customer_Scoping_Questionnaire__c(PreApprovalStatus__c = CSQAutomationTriggerHandler.PRE_APPROVAL_STATUS_APPROVED));
		csqs.add(new Customer_Scoping_Questionnaire__c(PreApprovalStatus__c = CSQAutomationTriggerHandler.PRE_APPROVAL_STATUS_PENDING_ONBOARDING));
		csqs.add(new Customer_Scoping_Questionnaire__c(PreApprovalStatus__c = CSQAutomationTriggerHandler.PRE_APPROVAL_STATUS_REFERRED));

		Map<String, List<SObject>> filteredGroupRecords = handler.primeRecordFilters(csqs);
		Assert.areEqual(3, filteredGroupRecords.size(), 'Expected the event records to be filtered into 3 groups');

		Assert.areEqual(1, filteredGroupRecords.get('filterCSQPreApprovalPending').size());
		Assert.areEqual(csqs[0].Id, filteredGroupRecords.get('filterCSQPreApprovalPending')[0].Id);

		Assert.areEqual(1, filteredGroupRecords.get('filterCSQPreApprovalReferred').size());
		Assert.areEqual(csqs[1].Id, filteredGroupRecords.get('filterCSQPreApprovalReferred')[0].Id);

		Assert.areEqual(1, filteredGroupRecords.get('filterCSQPreApprovalApproved').size());
		Assert.areEqual(csqs[2].Id, filteredGroupRecords.get('filterCSQPreApprovalApproved')[0].Id);
    }
}