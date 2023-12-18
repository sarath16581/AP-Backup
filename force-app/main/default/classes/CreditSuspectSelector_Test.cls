@isTest
public with sharing class CreditSuspectSelector_Test {
    // Basic coverage for CreditSuspectSelector class.
	@IsTest
	static void testSelector() {
		// Covering newInstance overloads
		CreditSuspectSelector.newInstance(0);
		CreditSuspectSelector.newInstance(0, new Set<SObjectField>());
		CreditSuspectSelector.newInstance(0, new Map<SObjectType,Set<SObjectField>>());
		// Requesting UserRecordAccess for and by Current User record
		Map<Id,CreditSuspect__c> cdMap = CreditSuspectSelector.newInstance().selectById(
			new Set<Id>{ fflib_IDGenerator.generate(CreditSuspect__c.SObjectType) }
		);
		
		System.assert(cdMap.isEmpty(), 'Shouldn\'t return any records');		
	}
}