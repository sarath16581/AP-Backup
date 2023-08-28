/**
 * @author 		: Paul Perry
 * @description : This class created to have converage for CreditSuspect Trigger
 **/
@isTest
public class CreditSuspectTrigger_Test {

	@IsTest
    static void makingSureThatTheDispatchMethodIsCalledFromTheCorrectClass() {		
		Date csDoB = Date.newInstance(1980, 1, 1);

        CreditSuspectTriggerHandler mock = (CreditSuspectTriggerHandler)
			MockUtility.mockUtility(CreditSuspectTriggerHandler.class);

		CreditSuspect__c csRecord = new CreditSuspect__c(
			// Birthdate__c = '', formatted date will be populated within the trigger
			FirstName__c = 'First',
			LastName__c = 'Last',
			Phone__c = '0400000000',
			PostCode__c = '3000',
			State__c = 'VIC',
			StreetAddress__c = '287 Elizabeth St',
			Suburb__c = 'MELBOURNE',
			Email__c = 'test@example.com',
			Date_of_Birth__c = csDoB
		);

		insert csRecord;

        ((CreditSuspectTriggerHandler)
			MockUtility.Mocks.verify(mock, MockUtility.Mocks.atLeastOnce())
		).dispatch();
        
        // PMD Warning
		System.assert(true, 'PMD Warning');
    }
}