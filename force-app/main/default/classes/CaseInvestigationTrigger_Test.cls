/**
 * @description       : This is a test class for the CaseInvestigationTrigger
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
**/
@IsTest
class CaseInvestigationTrigger_Test {
    
    @IsTest
    static void makingSureThatTheDispatchMethodIsCalledFromTheCorrectClass() {
        CaseInvestigationDomainTriggerHandler mock = (CaseInvestigationDomainTriggerHandler)MockUtility.mockUtility(CaseInvestigationDomainTriggerHandler.class);

        insert new CaseInvestigation__c();

        ((CaseInvestigationDomainTriggerHandler) MockUtility.Mocks.verify(mock, MockUtility.Mocks.atLeastOnce())).dispatch();

        // PMD Warning
		System.assert(true);
    }
}