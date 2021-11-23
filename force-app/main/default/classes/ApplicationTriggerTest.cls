/**************************************************
	Type:	Application Trigger Test Class
	History:
--------------------------------------------------
	09-07-2015: Eric Shen Auspost   Update Opp.stagename from 'Qualify' to 'Identify', and to 'Closed Lost' to avoid the new Validation rule error
 	09-07-2015: Christopher Henschke  Updated to add close reason and products.
	12-06-2018: TDO-48 : Hasantha.Liyanage@auspost.com.au Unit tests re-written with scenario based tests.
**************************************************/

@isTest
private class ApplicationTriggerTest {

    /**
     * Setup Initial Data
     */
    @testSetup static void setupInitialData() {
        // Account
        Account account = new Account(Name = 'Test Account');
        insert account;

        // Opportunity
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(
                Name = 'Test Opportunity 1',
                AccountId = account.Id,
                Offering_Type__c = 'Product',
                StageName = 'Identify',
                Probability = 3,
                CloseDate = System.today() + 2,
                Commit_to_close_by__c = Date.today(),
                Type = 'Existing Customer'));

        opportunities.add(new Opportunity(
                Name = 'Test Opportunity 2',
                AccountId = account.Id,
                Offering_Type__c = 'Product',
                StageName = 'Identify',
                Probability = 3,
                CloseDate = System.today() + 2,
                Commit_to_close_by__c = Date.today(),
                Type = 'Existing Customer'));
        insert opportunities;

        // Applications
        List<Application__c> applications = new List<Application__c>();
        for (Opportunity opportunity : opportunities) {
            // If 'Test Opportunity 1'
            if ('Test Opportunity 1'.equals(opportunity.Name)) {
                for (Integer i = 0; i < 20; i++) {
                    applications.add(new Application__c(
                            MCC__c = '1234',
                            SettlementProfile__c = '003 - 3 Days from Invoice',
                            RiskCategory__c = '001 - Very Low Risk',
                            EBTName__c = '123456789012',
                            Opportunity__c = opportunity.Id));
                }

            } // If 'Test Opportunity 2'
            else if ('Test Opportunity 2'.equals(opportunity.Name)) {
                for (Integer i = 0; i < 20; i++) {
                    applications.add(new Application__c(
                            Opportunity__c = opportunity.Id));
                }
            }
        }
        insert applications;
    }

    /**
     * SCENARIO: Successfully update Applications with and without values on Opportunity
     */
    @isTest static void ApplicationTriggerTest_appsWithandWithout_success() {
        // Load's the Opportunities
        List<String> opptNames = new List<String>{ 'Test Opportunity 1', 'Test Opportunity 2' };
        List<Opportunity> opportunities = [ SELECT Id FROM Opportunity WHERE Name IN :opptNames ];

        // Load's the Applications
        List<Application__c> applications = [ SELECT Id FROM Application__c WHERE Opportunity__c IN :opportunities ];

        Test.startTest();

        // Verify the Logic
        update applications;

        Test.stopTest();

        // Verify the Logic
        opportunities = [ SELECT Name, IsSettlementFieldsFilled__c FROM Opportunity WHERE Id IN :opportunities ];

        for (Opportunity opportunity : opportunities) {
            // If 'Test Opportunity 1'
            if ('Test Opportunity 1'.equals(opportunity.Name)) {
                System.assertEquals(opportunity.IsSettlementFieldsFilled__c,
                        true,
                        'ApplicationTriggerTest_appsWithandWithout_success : Settlement Fields Filled unsuccessful. Settlement Fields Filled should be true');

            } // If 'Test Opportunity 2'
            else if ('Test Opportunity 2'.equals(opportunity.Name)) {
                System.assertEquals(opportunity.IsSettlementFieldsFilled__c,
                        false,
                        'ApplicationTriggerTest_appsWithandWithout_success : Settlement Fields Filled unsuccessful. Settlement Fields Filled should be false');
            }
        }
    }
}